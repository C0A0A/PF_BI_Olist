from src.models.dbConnection import db_instance
from src.etl.etl_functions import export_to_csv
from settings.url_constants import RESOURCES_DIR
import uuid

def get_datasource_list():
    df = db_instance.get_data_from_query("SELECT viewname FROM pg_views WHERE schemaname = 'public';")
    return df['viewname'].tolist()

def get_data_from_db_source(source_name):
    df = db_instance.get_data_from_query(f"SELECT * FROM {source_name};")
    if df.empty:
        raise ValueError(f"No se encontraron datos en la fuente '{source_name}' o no existe.")
    url = f"{RESOURCES_DIR}/{source_name}_{str(uuid.uuid4())}.csv"
    export_to_csv(df, url)
        
    return url
