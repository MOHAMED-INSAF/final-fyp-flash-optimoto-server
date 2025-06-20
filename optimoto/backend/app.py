from flask import Flask, request, jsonify, make_response
from flask_cors import CORS, cross_origin
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from datetime import timedelta
import bcrypt
import pandas as pd
import json
import logging
from database import db
from models import User, Vehicle, Wishlist
import os
from sklearn.model_selection import cross_val_score
from sklearn.metrics import mean_squared_error, mean_absolute_error
import numpy as np
from ml_model import VehicleRecommender

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config.from_object('config')
app.config['DEBUG'] = True

# Initialize extensions
db.init_app(app)
jwt = JWTManager(app)

# Simplify CORS configuration
CORS(app)

@app.after_request
def after_request(response):
    response.headers.update({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    })
    return response

# Routes
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already registered'}), 400
    
    hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
    
    new_user = User(
        email=data['email'],
        password=hashed_password
    )
    
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    
    if user and bcrypt.checkpw(data['password'].encode('utf-8'), user.password):
        access_token = create_access_token(
            identity=user.id,
            expires_delta=timedelta(days=1)
        )
        return jsonify({'token': access_token}), 200
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/profile', methods=['GET', 'PUT'])
@jwt_required()
def profile():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if request.method == 'GET':
        return jsonify({
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'phone': user.phone
        })
    
    data = request.get_json()
    user.first_name = data.get('first_name', user.first_name)
    user.last_name = data.get('last_name', user.last_name)
    user.phone = data.get('phone', user.phone)
    
    db.session.commit()
    return jsonify({'message': 'Profile updated successfully'})

@app.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    try:
        # Read the CSV file
        csv_path = os.path.join(os.path.dirname(__file__), 'data', 'vehicles_dataset.csv')
        df = pd.read_csv(csv_path)
        
        # Convert to list of dictionaries with proper column mapping
        formatted_vehicles = []
        for index, row in df.iterrows():
            vehicle = {
                'id': str(index),
                'name': f"{row['make']} {row['model']}",  # Combine make and model
                'brand': row['make'],
                'price': float(row['price']),
                'type': row['type'],
                'mileage': float(row['mileage']),
                'fuelType': row['fuel'],
                'score': float(row.get('score', 0.9)),
                'imageUrl': row.get('image_url', '')
            }
            formatted_vehicles.append(vehicle)
        
        print(f"Sending {len(formatted_vehicles)} vehicles")  # Debug log
        return jsonify(formatted_vehicles)
    except Exception as e:
        print(f"Error loading vehicles: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/wishlist', methods=['GET', 'POST', 'DELETE'])
@jwt_required()
def wishlist():
    user_id = get_jwt_identity()
    
    if request.method == 'GET':
        wishlist_items = Wishlist.query.filter_by(user_id=user_id).all()
        vehicles = [Vehicle.query.get(item.vehicle_id) for item in wishlist_items]
        return jsonify([{
            'id': v.id,
            'name': v.name,
            'price': v.price,
            'image_url': v.image_url
        } for v in vehicles])
    
    elif request.method == 'POST':
        data = request.get_json()
        new_wishlist_item = Wishlist(
            user_id=user_id,
            vehicle_id=data['vehicle_id']
        )
        db.session.add(new_wishlist_item)
        db.session.commit()
        return jsonify({'message': 'Added to wishlist'})
    
    else:  # DELETE
        data = request.get_json()
        Wishlist.query.filter_by(
            user_id=user_id,
            vehicle_id=data['vehicle_id']
        ).delete()
        db.session.commit()
        return jsonify({'message': 'Removed from wishlist'})

@app.route('/api/recommendations', methods=['GET'])
def get_recommendations():
    try:
        logger.debug("=== Received recommendation request ===")
        logger.debug(f"Request args: {request.args}")

        # Get parameters from request
        min_price = float(request.args.get('min_price', 0))
        max_price = float(request.args.get('max_price', 100000))
        min_mileage = float(request.args.get('min_mileage', 0))
        max_mileage = float(request.args.get('max_mileage', 50))
        purpose = request.args.get('purpose', 'Urban')
        fuel_type = request.args.get('fuel_type')
        vehicle_types = json.loads(request.args.get('vehicle_types', '[]'))
        brands = json.loads(request.args.get('brands', '[]'))
        limit = int(request.args.get('limit', 5))

        # Check if dataset exists
        csv_path = os.path.join(os.path.dirname(__file__), 'data', 'vehicles_dataset.csv')
        if not os.path.exists(csv_path):
            logger.error(f"Dataset not found at: {csv_path}")
            return jsonify({
                'error': 'Dataset not found',
                'message': f'Could not find dataset at {csv_path}'
            }), 500

        # Read the dataset
        df = pd.read_csv(csv_path)
        logger.debug(f"Loaded dataset with {len(df)} rows")
        logger.debug(f"Columns: {df.columns.tolist()}")

        # Apply filters
        mask = pd.Series(True, index=df.index)

        # Price filter
        df['price'] = pd.to_numeric(df['price'], errors='coerce')
        mask &= (df['price'] >= min_price) & (df['price'] <= max_price)

        # Mileage filter
        df['mileage'] = pd.to_numeric(df['mileage'], errors='coerce')
        mask &= (df['mileage'] >= min_mileage) & (df['mileage'] <= max_mileage)

        # Fuel type filter
        if fuel_type:
            mask &= df['fuel'].str.contains(fuel_type, case=False, na=False)

        # Vehicle type filter
        if vehicle_types:
            type_mask = pd.Series(False, index=df.index)
            for vtype in vehicle_types:
                type_mask |= df['type'].str.contains(vtype, case=False, na=False)
            mask &= type_mask

        # Brand filter
        if brands:
            brand_mask = pd.Series(False, index=df.index)
            for brand in brands:
                brand_mask |= df['make'].str.contains(brand, case=False, na=False)
            mask &= brand_mask

        filtered_df = df[mask].copy()
        logger.debug(f"Filtered to {len(filtered_df)} vehicles")

        if filtered_df.empty:
            return jsonify({
                'error': 'no_matches',
                'message': 'No vehicles match your criteria'
            }), 404

        # Calculate scores (simplified for testing)
        filtered_df['score'] = 1.0

        # Get recommendations
        recommendations = filtered_df.nlargest(limit, 'score')
        
        # Convert to list of dictionaries
        result = []
        for _, row in recommendations.iterrows():
            vehicle = {
                'id': str(row.name),
                'name': f"{row['make']} {row['model']}".strip(),
                'price': float(row['price']),
                'mileage': float(row['mileage']),
                'type': str(row['type']),
                'brand': str(row['make']),
                'fuel_type': str(row['fuel']),
                'year': int(row.get('year', 2023)),
                'score': float(row.get('score', 1.0)),
            }
            result.append(vehicle)

        logger.debug(f"Returning {len(result)} recommendations")
        return jsonify(result)

    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'internal_error',
            'message': str(e)
        }), 500

@app.route('/api/test', methods=['GET'])
@cross_origin()
def test():
    return jsonify({'message': 'API is working'})

@app.route('/api/vehicle-types', methods=['GET'])
def get_vehicle_types():
    try:
        csv_path = os.path.join(os.path.dirname(__file__), 'data', 'vehicles_dataset.csv')
        df = pd.read_csv(csv_path)
        # Get unique types, sort them, and remove any NaN values
        types = sorted(df['type'].dropna().unique().tolist())
        return jsonify(types)
    except Exception as e:
        logger.error(f"Error getting vehicle types: {str(e)}")
        return jsonify([]), 500

@app.route('/api/brands', methods=['GET'])
def get_brands():
    try:
        csv_path = os.path.join(os.path.dirname(__file__), 'data', 'vehicles_dataset.csv')
        df = pd.read_csv(csv_path)
        # Get unique makes (brands), sort them, and remove any NaN values
        brands = sorted(df['make'].dropna().unique().tolist())
        return jsonify(brands)
    except Exception as e:
        logger.error(f"Error getting brands: {str(e)}")
        return jsonify([]), 500

def initialize_database():
    logger.info("Initializing database with vehicles...")
    try:
        # Load vehicles from CSV
        df = pd.read_csv('data/vehicles_dataset.csv')
        logger.info(f"Loaded {len(df)} vehicles from dataset")
        logger.info(f"Available columns: {df.columns.tolist()}")  # Print available columns
        
        # Create all tables
        db.create_all()
        
        # Add vehicles to database
        for _, row in df.iterrows():
            # Map the columns from your actual dataset to the required fields
            vehicle = Vehicle(
                name=row.get('name', row.get('model', 'Unknown')),  # Try 'model' if 'name' doesn't exist
                price=float(row.get('price', 0)),
                type=row.get('type', row.get('vehicle_type', 'Unknown')),  # Try 'vehicle_type' if 'type' doesn't exist
                brand=row.get('brand', row.get('make', 'Unknown')),  # Try 'make' if 'brand' doesn't exist
                year=int(row.get('year', 2023)),
                image_url=row.get('image_url', '')
            )
            db.session.add(vehicle)
        
        db.session.commit()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {str(e)}", exc_info=True)
        raise

def evaluate_ml_model():
    try:
        logger.info("=== Evaluating ML Model ===")
        
        # Initialize the model
        dataset_path = os.path.join(os.path.dirname(__file__), 'data', 'vehicles_dataset.csv')
        recommender = VehicleRecommender(dataset_path)
        
        # Get features and target
        feature_columns = ['price', 'mileage', 'fuel', 'body', 'Purpose', 
                         'Detailed_Purpose', 'cylinders', 'Displacement (cc)', 'drivetrain']
        X = recommender.vehicles_df[feature_columns]
        y = recommender.vehicles_df['mileage']
        
        # Prepare data
        X = pd.DataFrame(recommender.imputer.transform(X), columns=feature_columns)
        X_scaled = recommender.scaler.transform(X)
        
        # Perform cross-validation
        cv_scores = cross_val_score(recommender.model, X_scaled, y, 
                                  cv=5, scoring='neg_mean_squared_error')
        mse_scores = -cv_scores  # Convert negative MSE to positive
        
        # Calculate metrics
        y_pred = recommender.model.predict(X_scaled)
        mse = mean_squared_error(y, y_pred)
        mae = mean_absolute_error(y, y_pred)
        
        # Print results
        logger.info("\nML Model Evaluation Results:")
        logger.info(f"Cross-Validation MSE Scores: {mse_scores}")
        logger.info(f"Average Cross-Validation MSE: {np.mean(mse_scores)}")
        logger.info(f"Model MSE: {mse}, MAE: {mae}")
        
        return recommender
    except Exception as e:
        logger.error(f"Error evaluating ML model: {str(e)}")
        return None

if __name__ == '__main__':
    with app.app_context():
        initialize_database()
        # Add ML model evaluation
        logger.info("\nInitializing and evaluating ML model...")
        recommender = evaluate_ml_model()
        if recommender:
            logger.info("ML model initialized successfully")
        else:
            logger.warning("Failed to initialize ML model")
    
    app.run(
        host='0.0.0.0',
        port=5001,
        debug=True
    ) 