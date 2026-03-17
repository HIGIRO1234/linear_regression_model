# Student GPA Prediction Model

## Mission and Problem
In Rwanda and across Africa, schools and educators lack data-driven 
tools to identify students at risk of poor academic performance before 
it is too late to intervene effectively. The problem is that without 
a predictive model, teachers cannot proactively support struggling 
students leading to high failure rates and increased dropout especially 
in underserved communities. This project builds a machine learning 
regression model that predicts student GPA based on study habits, 
attendance, parental support and extracurricular activities, enabling 
Rwandan schools and educators to identify at-risk students early and 
provide targeted academic interventions before performance deteriorates.

## Dataset
- **Name:** Students Performance Dataset
- **Source:** [Kaggle]('kaggle.com/datasets/rabieelkharoua/students-performance-dataset')
- **Description:** The dataset contains 2,392 records of high school 
students with 15 columns covering demographics, study habits, parental 
involvement, extracurricular activities and academic performance. 
The target variable is GPA which represents the student Grade Point 
Average ranging from 0.0 to 4.0. The dataset includes features such 
as Age, Gender, Ethnicity, ParentalEducation, StudyTimeWeekly, 
Absences, Tutoring, ParentalSupport, Extracurricular, Sports, Music 
and Volunteering making it rich in both volume and variety for 
regression analysis.

## Project Structure
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb
│   ├── API/
│   └── FlutterApp/
│
└── README.md

## Key Findings
- Absences is the strongest predictor of GPA with a correlation of -0.92
- More absences = significantly lower GPA confirmed by all three models
- StudyTimeWeekly and Tutoring are the second and third strongest predictors
- ParentalSupport shows a clear positive impact on student GPA

## Models Used
- Linear Regression (Ordinary Least Squares)
- Decision Tree Regressor
- Random Forest Regressor

## Model Performance

| Model             | Test MSE | Test MAE | Test R2 |
|-------------------|----------|----------|---------|
| Linear Regression | 0.0385   | 0.1551   | 0.9534  |
| Decision Tree     | 0.1202   | 0.2792   | 0.8547  |
| Random Forest     | 0.0876   | 0.2342   | 0.8940  |

## Best Model
Linear Regression achieved the best overall performance with a Test 
R2 of 0.9534 which means the model explains 95% of the variance in 
student GPA. The Train R2 of 0.9542 and Test R2 of 0.9534 are almost 
identical which confirms the model generalizes perfectly to unseen 
student data without any overfitting. The model was saved as 
best_model.pkl and the scaler was saved as scaler.pkl.

## Gradient Descent Results
- Starting Train Loss : 1.0000
- Final   Train Loss  : 0.0707
- Starting Test Loss  : 0.9674
- Final   Test Loss   : 0.0773
- Loss Reduction Train: 0.9293
- Loss Reduction Test : 0.8902

## Dataset Note
This model was trained on a publicly available dataset from Kaggle 
since equivalent Rwandan student performance data is not yet publicly 
available. The same model architecture and approach can be retrained 
on Rwandan school data once it becomes available, making it directly 
applicable to the local education context.

## How to Run
1. Clone the repository
2. Open summative/linear_regression/multivariate.ipynb
3. Run all cells in order
4. The best model will be saved automatically as best_model.pkl

## Requirements
- Python 3.x
- pandas
- numpy
- matplotlib
- seaborn
- scikit-learn
- joblib
