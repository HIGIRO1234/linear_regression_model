import os
import io
import pickle
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score

#  App setup
app = FastAPI(
    title="Student GPA Prediction API",
    description=(
        "Predicts a student's GPA based on academic and personal factors "
        "using a Random-Forest model trained on the Kaggle Students Performance dataset."
    ),
    version="1.0.0",
)


#  CORS – explicit, not wildcard
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8000",
        # Render-hosted front-end / Flutter web preview
        "https://student-gpa-predictor.onrender.com",
        # Flutter mobile apps reach the API directly; no origin restriction needed
        # for native apps, but we list common dev hosts for web/emulator use.
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Accept", "X-Requested-With"],
)

#  Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(BASE_DIR, "scaler.pkl")
DATA_URL = (
    "https://raw.githubusercontent.com/HIGIRO1234/linear_regression_model"
    "/main/Student_performance_data%20_.csv"
)


#  Load artefacts
def load_model():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"Model file not found at {MODEL_PATH}. "
            "Please run the training notebook first."
        )
    with open(MODEL_PATH, "rb") as f:
        return pickle.load(f)


def load_scaler():
    if not os.path.exists(SCALER_PATH):
        raise FileNotFoundError(
            f"Scaler file not found at {SCALER_PATH}. "
            "Please run the training notebook first."
        )
    with open(SCALER_PATH, "rb") as f:
        return pickle.load(f)

#  Pydantic schemas
# ── Lookup tables ──────────────────────────────────────────────────────────────
_YES_NO       = {"yes": 1, "no": 0}
_ETHNICITY    = {"caucasian": 0, "african american": 1, "asian": 2, "other": 3}
_PARENTAL_EDU = {"none": 0, "high school": 1, "some college": 2, "bachelors": 3, "higher": 4}
_PARENTAL_SUP = {"none": 0, "low": 1, "moderate": 2, "high": 3, "very high": 4}

def _yn(field: str, value: str) -> int:
    v = value.strip().lower()
    if v not in _YES_NO:
        raise ValueError(f"{field} must be 'yes' or 'no'")
    return _YES_NO[v]


class StudentFeatures(BaseModel):
    age: int = Field(..., ge=15, le=18, description="Student age (15–18)")
    gender: str = Field(..., description="'male' or 'female'")
    study_time_weekly: float = Field(..., ge=0.0, le=20.0, description="Weekly study hours (0–20)")
    absences: int = Field(..., ge=0, le=30, description="Number of absences (0–30)")
    tutoring: str = Field(..., description="'yes' or 'no'")
    extracurricular: str = Field(..., description="'yes' or 'no'")
    sports: str = Field(..., description="'yes' or 'no'")
    music: str = Field(..., description="'yes' or 'no'")
    volunteering: str = Field(..., description="'yes' or 'no'")
    ethnicity: str = Field(..., description="'caucasian' | 'african american' | 'asian' | 'other'")
    parental_education: str = Field(..., description="'none' | 'high school' | 'some college' | 'bachelors' | 'higher'")
    parental_support: str = Field(..., description="'none' | 'low' | 'moderate' | 'high' | 'very high'")

    @field_validator("gender")
    @classmethod
    def _parse_gender(cls, v):
        val = v.strip().lower()
        if val not in ("male", "female"):
            raise ValueError("gender must be 'male' or 'female'")
        return val

    @field_validator("tutoring", "extracurricular", "sports", "music", "volunteering")
    @classmethod
    def _parse_yes_no(cls, v, info):
        val = v.strip().lower()
        if val not in _YES_NO:
            raise ValueError(f"{info.field_name} must be 'yes' or 'no'")
        return val

    @field_validator("ethnicity")
    @classmethod
    def _parse_ethnicity(cls, v):
        val = v.strip().lower()
        if val not in _ETHNICITY:
            raise ValueError(f"ethnicity must be one of: {list(_ETHNICITY.keys())}")
        return val

    @field_validator("parental_education")
    @classmethod
    def _parse_parental_education(cls, v):
        val = v.strip().lower()
        if val not in _PARENTAL_EDU:
            raise ValueError(f"parental_education must be one of: {list(_PARENTAL_EDU.keys())}")
        return val

    @field_validator("parental_support")
    @classmethod
    def _parse_parental_support(cls, v):
        val = v.strip().lower()
        if val not in _PARENTAL_SUP:
            raise ValueError(f"parental_support must be one of: {list(_PARENTAL_SUP.keys())}")
        return val

    model_config = {
        "json_schema_extra": {
            "example": {
                "age": 16,
                "gender": "male",
                "study_time_weekly": 15.0,
                "absences": 3,
                "tutoring": "yes",
                "extracurricular": "yes",
                "sports": "no",
                "music": "no",
                "volunteering": "no",
                "ethnicity": "caucasian",
                "parental_education": "bachelors",
                "parental_support": "high",
            }
        }
    }


class PredictionResponse(BaseModel):
    predicted_gpa: float


class RetrainResponse(BaseModel):
    message: str
    linear_regression_r2: float
    decision_tree_r2: float
    random_forest_r2: float
    best_model: str
    best_r2: float


#  Feature engineering helper
def build_feature_vector(data: StudentFeatures) -> np.ndarray:

    # Convert human-readable strings → numbers
    gender_num      = 1 if data.gender == "male" else 0
    tutoring_num    = _YES_NO[data.tutoring]
    extra_num       = _YES_NO[data.extracurricular]
    sports_num      = _YES_NO[data.sports]
    music_num       = _YES_NO[data.music]
    volunteer_num   = _YES_NO[data.volunteering]
    eth_idx         = _ETHNICITY[data.ethnicity]
    edu_idx         = _PARENTAL_EDU[data.parental_education]
    sup_idx         = _PARENTAL_SUP[data.parental_support]

    # drop_first=True OHE — reference category (0) is dropped, matches 20-feature training
    ethnicity_ohe    = [1 if eth_idx == i else 0 for i in range(1, 4)]   # cols 1,2,3
    parental_edu_ohe = [1 if edu_idx == i else 0 for i in range(1, 5)]   # cols 1,2,3,4
    parental_sup_ohe = [1 if sup_idx == i else 0 for i in range(1, 5)]   # cols 1,2,3,4

    feature_vector = (
        [
            data.age,
            gender_num,
            data.study_time_weekly,
            data.absences,
            tutoring_num,
            extra_num,
            sports_num,
            music_num,
            volunteer_num,
        ]
        + ethnicity_ohe
        + parental_edu_ohe
        + parental_sup_ohe
    )
    return np.array(feature_vector).reshape(1, -1)


#  Training helper (used by /retrain endpoints)
def preprocess_and_train(df: pd.DataFrame) -> dict:
    """Full pipeline: clean → encode → scale → train 3 models → save best."""
    df = df.drop_duplicates()
    df = df.dropna()

    # Drop columns not used in the original training
    drop_cols = [c for c in ["StudentID", "GradeClass"] if c in df.columns]
    df = df.drop(columns=drop_cols)

    target = "GPA"
    if target not in df.columns:
        raise ValueError("Dataset must contain a 'GPA' column.")

    # Identify categorical columns for one-hot encoding
    cat_cols = df.select_dtypes(include=["object", "category"]).columns.tolist()
    if cat_cols:
        df = pd.get_dummies(df, columns=cat_cols, drop_first=False)

    # One-hot encode known integer-coded categoricals (drop_first=True → 20 features)
    for col in ["Ethnicity", "ParentalEducation", "ParentalSupport"]:
        if col in df.columns:
            dummies = pd.get_dummies(df[col], prefix=col, drop_first=True).astype(int)
            df = pd.concat([df.drop(columns=[col]), dummies], axis=1)

    X = df.drop(columns=[target])
    y = df[target]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc = scaler.transform(X_test)

    results = {}

    lr = LinearRegression()
    lr.fit(X_train_sc, y_train)
    results["Linear Regression"] = {
        "model": lr,
        "r2": r2_score(y_test, lr.predict(X_test_sc)),
    }

    dt = DecisionTreeRegressor(random_state=42)
    dt.fit(X_train_sc, y_train)
    results["Decision Tree"] = {
        "model": dt,
        "r2": r2_score(y_test, dt.predict(X_test_sc)),
    }

    rf = RandomForestRegressor(n_estimators=100, random_state=42)
    rf.fit(X_train_sc, y_train)
    results["Random Forest"] = {
        "model": rf,
        "r2": r2_score(y_test, rf.predict(X_test_sc)),
    }

    best_name = max(results, key=lambda k: results[k]["r2"])
    best_model = results[best_name]["model"]

    with open(MODEL_PATH, "wb") as f:
        pickle.dump(best_model, f)
    with open(SCALER_PATH, "wb") as f:
        pickle.dump(scaler, f)

    return {
        "linear_regression_r2": round(results["Linear Regression"]["r2"], 4),
        "decision_tree_r2": round(results["Decision Tree"]["r2"], 4),
        "random_forest_r2": round(results["Random Forest"]["r2"], 4),
        "best_model": best_name,
        "best_r2": round(results[best_name]["r2"], 4),
    }

#  Routes
@app.get("/", tags=["Health"])
def root():
    return {
        "status": "running",
        "docs": "/docs",
        "message": "Student GPA Prediction API",
    }


@app.get("/health", tags=["Health"])
def health_check():
    model_ready = os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH)
    return {"status": "ok", "model_ready": model_ready}


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict_gpa(student: StudentFeatures):

    try:
        model = load_model()
        scaler = load_scaler()
    except FileNotFoundError as exc:
        raise HTTPException(status_code=503, detail=str(exc))

    features = build_feature_vector(student)

    try:
        features_scaled = scaler.transform(features)
    except Exception as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Feature scaling failed: {exc}",
        )

    prediction = model.predict(features_scaled)[0]
    predicted_gpa = float(np.clip(prediction, 0.0, 4.0))

    return PredictionResponse(predicted_gpa=round(predicted_gpa, 4))


@app.post("/retrain", response_model=RetrainResponse, tags=["Model Management"])
async def retrain_with_upload(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(
        ...,
        description=(
            "Upload a CSV file with the same schema as the original dataset "
            "(must include a 'GPA' column)."
        ),
    ),
):

    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are accepted.")

    contents = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(contents))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV: {exc}")

    if df.empty or len(df) < 10:
        raise HTTPException(
            status_code=400, detail="Dataset too small (need at least 10 rows)."
        )

    try:
        metrics = preprocess_and_train(df)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Training failed: {exc}")

    return RetrainResponse(
        message="Models retrained successfully on uploaded data. Best model saved.",
        **metrics,
    )


@app.post("/retrain/default", response_model=RetrainResponse, tags=["Model Management"])
def retrain_with_default_data(background_tasks: BackgroundTasks):
    """
    Retrain using the original Kaggle dataset (fetched from GitHub).
    Useful for resetting the model to its baseline state.
    """
    try:
        df = pd.read_csv(DATA_URL)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Could not fetch default dataset: {exc}",
        )

    try:
        metrics = preprocess_and_train(df)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Training failed: {exc}")

    return RetrainResponse(
        message="Models retrained successfully on default dataset. Best model saved.",
        **metrics,
    )
