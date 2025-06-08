from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from fastapi.responses import RedirectResponse, FileResponse
from typing import List

from src.models.apiDto import DwTables, TransferMethod, ETLResponse, ErrorResponse
from src.datasources.main import get_data_from_db_source, get_datasource_list
from src.etl.main import exec_etl_job, transfer_stg_to_prod
from src.utils.log import logInfo
from settings import API_TOKEN

app = FastAPI(title="OLIST ETL API")


api_key_header = APIKeyHeader(name="Authorization", auto_error=False)


# Dependencia para validar el token de API
def get_api_key(api_key: str = Depends(api_key_header)):
    if api_key == API_TOKEN:
        return api_key
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token no válido",
            headers={"WWW-Authenticate": "Bearer"},
        )


@app.get("/", include_in_schema=False)
def read_root():
    return RedirectResponse(url="/docs", status_code=303)


@app.get("/health-check", tags=["Health Check"])
def health_check():
    """
    Health check simple para verificar si la API está disponible.
    """
    return {"status": "ok"}


@app.get(
    "/datasources",
    response_model=List[str],
    summary="Listar fuentes de datos",
    description="Devuelve el listado de recursos disponibles en la DB.",
    tags=["Fuentes de datos"]
)
def get_all_datasources(api_key: str = Depends(get_api_key)):
    return get_datasource_list()


@app.get(
    "/datasources/{data_source}",
    summary="Descargar datos de una fuente",
    description="Devuelve un archivo CSV con los datos de la fuente especificada.",
    responses={
        200: {
            "content": {"text/csv": {}},
            "description": "Archivo CSV generado con éxito",
        },
        400: {"model": ErrorResponse, "description": "Error durante la ejecución"},
    },
    tags=["Fuentes de datos"]
)
def get_data(data_source: str, api_key: str = Depends(get_api_key)):
    try:
        file_url = get_data_from_db_source(data_source)
        return FileResponse(file_url, filename=data_source, media_type="text/csv")

    except Exception as e:
        logInfo(f"Error en get_data: {e}")
        result = {
            "success": False,
            "message": "Error durante la ejecución. Ver detalle en logs.",
        }

    return result


@app.post(
    "/etl-jobs/stg/{job_key}",
    response_model=ETLResponse,
    summary="Ejecuta procesos ETL en STAGING",
    description="Respetar el orden de ejecución.",
    tags=["ETL jobs"]
)
def exec_job_stg(job_key: DwTables, api_key: str = Depends(get_api_key)):
    try:
        rows_affected = exec_etl_job(job_key)
        result = {"success": True, "message": "OK", "rows_affected": rows_affected}
    except Exception as e:
        logInfo(f"Error en etl-jobs-stg: {e}")
        result = {
            "success": False,
            "message": "Error durante la ejecución. Ver detalle en logs.",
            "rows_affected": 0,
        }

    return result


@app.post(
    "/etl-jobs/prod/{job_key}",
    response_model=ETLResponse,
    summary="Desplegar datos de STAGING a PRODUCCIÓN",
    description="Respetar el orden de ejecución.",
    tags=["ETL jobs"]
)
def exec_job_prod(
    job_key: DwTables, method: TransferMethod, api_key: str = Depends(get_api_key)
):
    try:
        rows_affected = transfer_stg_to_prod(job_key, method)
        result = {"success": True, "message": "OK", "rows_affected": rows_affected}
    except Exception as e:
        logInfo(f"Error en etl-jobs-prod: {e}")
        result = {
            "success": False,
            "message": "Error durante la ejecución. Ver detalle en logs.",
            "rows_affected": 0,
        }

    return result
