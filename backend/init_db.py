from flask import Flask
import pandas as pd
import logging
from database import db
from models import User, Vehicle, Wishlist

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def create_app():
    app = Flask(__name__)
    app.config.from_object('config')
    db.init_app(app)
    return app

def init_database():
    app = create_app()
    with app.app_context():
        logger.debug("Creating database tables...")
        # Create all tables
        db.create_all()
        
        logger.debug("Reading vehicles dataset...")
        # Load vehicles from CSV with correct path
        try:
            df = pd.read_csv('data/vehicles_dataset.csv')
            logger.debug(f"Loaded {len(df)} vehicles from dataset")
            logger.debug(f"Available columns: {df.columns.tolist()}")
            
            # Add vehicles to database
            for _, row in df.iterrows():
                try:
                    vehicle = Vehicle(
                        name=row.get('name', row.get('model', 'Unknown')),
                        price=float(row.get('price', 0)),
                        type=row.get('type', row.get('vehicle_type', 'Unknown')),
                        brand=row.get('brand', row.get('make', 'Unknown')),
                        year=int(row.get('year', 2023)),
                        image_url=row.get('image_url', '')
                    )
                    db.session.add(vehicle)
                except Exception as e:
                    logger.error(f"Error adding vehicle: {str(e)}")
                    continue
            
            logger.debug("Committing changes to database...")
            db.session.commit()
            logger.debug("Database initialization complete")
        except Exception as e:
            logger.error(f"Error loading dataset: {str(e)}")
            db.session.rollback()
            raise

if __name__ == '__main__':
    init_database() 