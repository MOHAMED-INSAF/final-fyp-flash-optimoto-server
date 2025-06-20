import pandas as pd
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LinearRegression

class VehicleRecommender:
    def __init__(self, dataset_path):
        self.vehicles_df = pd.read_csv(dataset_path)
        
        # Add missing columns with default values if they don't exist
        required_columns = ['price', 'mileage', 'fuel', 'body', 'Purpose', 
                           'Detailed_Purpose', 'cylinders', 'Displacement (cc)', 
                           'drivetrain']
        
        for col in required_columns:
            if col not in self.vehicles_df.columns:
                if col in ['price', 'mileage', 'cylinders', 'Displacement (cc)']:
                    self.vehicles_df[col] = 0
                else:
                    self.vehicles_df[col] = 'Unknown'
        
        self.vehicles_df['price'] = pd.to_numeric(self.vehicles_df['price'], 
                                                errors='coerce').fillna(0).round(0).astype(int)
        
        # Initialize encoders and transformers
        self.label_encoders = {}
        self.setup_encoders()
        self.setup_model()
        
    def setup_encoders(self):
        for col in ['fuel', 'body', 'Purpose', 'Detailed_Purpose', 'drivetrain']:
            le = LabelEncoder()
            self.vehicles_df[col] = le.fit_transform(self.vehicles_df[col])
            self.label_encoders[col] = dict(zip(le.classes_, le.transform(le.classes_)))
            
    def setup_model(self):
        feature_columns = ['price', 'mileage', 'fuel', 'body', 'Purpose', 
                         'Detailed_Purpose', 'cylinders', 'Displacement (cc)', 'drivetrain']
        X = self.vehicles_df[feature_columns]
        y = self.vehicles_df['mileage']
        
        self.imputer = SimpleImputer(strategy='median')
        X = pd.DataFrame(self.imputer.fit_transform(X), columns=feature_columns)
        
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)
        
        self.model = LinearRegression()
        self.model.fit(X_scaled, y)
        
    def calculate_purpose_score(self, row, user_purpose):
        if user_purpose == 'Urban':
            return (0.5 * row['mileage']) + (0.3 / row['price']) + (0.2 / row['Displacement (cc)'])
        elif user_purpose == 'Touring':
            return (0.4 * row['mileage']) + (0.3 / row['price']) + (0.2 * row['fuel']) + (0.1 * row['Displacement (cc)'])
        elif user_purpose == 'Racing':
            return (0.4 * row['cylinders']) + (0.3 * row['body']) + (0.2 * row['price']) + (0.1 * row['Displacement (cc)'])
        return 0
        
    def recommend_vehicles(self, user_budget_min, user_budget_max, mileage_min, mileage_max,
                         user_fuel, user_body, user_drivetrain, purpose, top_n=5):
        purpose_map = {'Urban': 0, 'Touring': 1, 'Racing': 2}
        purpose_code = purpose_map.get(purpose, 1)
        
        conditions = [
            (self.vehicles_df['price'] >= user_budget_min),
            (self.vehicles_df['price'] <= user_budget_max),
            (self.vehicles_df['mileage'] >= mileage_min),
            (self.vehicles_df['mileage'] <= mileage_max),
            (self.vehicles_df['Detailed_Purpose'] == purpose_code)
        ]
        
        if user_fuel != "Any":
            conditions.append(self.vehicles_df['fuel'] == self.label_encoders['fuel'][user_fuel])
        if user_body != "Any":
            conditions.append(self.vehicles_df['body'] == self.label_encoders['body'][user_body])
        if user_drivetrain != "Any":
            conditions.append(self.vehicles_df['drivetrain'] == self.label_encoders['drivetrain'][user_drivetrain])
        
        filtered_df = self.vehicles_df.copy()
        for condition in conditions:
            filtered_df = filtered_df[condition]
            
        filtered_df['suitability_score'] = filtered_df.apply(
            lambda row: self.calculate_purpose_score(row, purpose), axis=1
        )
        
        recommended = filtered_df.sort_values(by='suitability_score', ascending=False).head(top_n)
        return recommended[['name', 'price', 'mileage', 'fuel', 'body', 'Purpose', 
                          'Detailed_Purpose', 'drivetrain', 'suitability_score']] 