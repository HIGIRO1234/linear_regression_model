"""
One-time script to train models and save best_model.pkl + scaler.pkl.
Mirrors the training pipeline in multivariate.ipynb.
"""
import pickle
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score

DATA_URL = (
    "https://raw.githubusercontent.com/HIGIRO1234/linear_regression_model"
    "/main/Student_performance_data%20_.csv"
)

print("Loading dataset...")
df = pd.read_csv(DATA_URL)
print(f"  Shape: {df.shape}")

# ── Clean ──────────────────────────────────────────────────────────────────────
df = df.drop(columns=["StudentID", "GradeClass"], errors="ignore")
df = df.drop_duplicates().dropna()

# ── One-hot encode (drop_first=True to match notebook) ────────────────────────
for col in ["Ethnicity", "ParentalEducation", "ParentalSupport"]:
    dummies = pd.get_dummies(df[col], prefix=col, drop_first=True).astype(int)
    df = pd.concat([df.drop(columns=[col]), dummies], axis=1)

# Convert any remaining bool columns to int
bool_cols = df.select_dtypes(bool).columns
df[bool_cols] = df[bool_cols].astype(int)

# ── Split ──────────────────────────────────────────────────────────────────────
X = df.drop(columns=["GPA"])
y = df["GPA"]
print(f"  Features: {X.columns.tolist()}")

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# ── Scale ──────────────────────────────────────────────────────────────────────
scaler = StandardScaler()
X_train_sc = scaler.fit_transform(X_train)
X_test_sc  = scaler.transform(X_test)

# ── Train all three models ─────────────────────────────────────────────────────
models = {
    "Linear Regression": LinearRegression(),
    "Decision Tree":     DecisionTreeRegressor(random_state=42),
    "Random Forest":     RandomForestRegressor(n_estimators=100, random_state=42),
}

results = {}
for name, model in models.items():
    model.fit(X_train_sc, y_train)
    preds = model.predict(X_test_sc)
    results[name] = {
        "model": model,
        "r2":    r2_score(y_test, preds),
        "mae":   mean_absolute_error(y_test, preds),
    }
    print(f"  {name:22s}  R²={results[name]['r2']:.4f}  MAE={results[name]['mae']:.4f}")

# ── Save best ──────────────────────────────────────────────────────────────────
best_name  = max(results, key=lambda k: results[k]["r2"])
best_model = results[best_name]["model"]

with open("best_model.pkl", "wb") as f:
    pickle.dump(best_model, f)
with open("scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)

print(f"\nBest model: {best_name}  (R²={results[best_name]['r2']:.4f})")
print("Saved → best_model.pkl, scaler.pkl")
