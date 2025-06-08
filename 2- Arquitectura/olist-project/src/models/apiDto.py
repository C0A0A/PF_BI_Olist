from pydantic import BaseModel
from enum import Enum


class DwTables(Enum):
    CUSTOMERS = "customers"
    ORDERS = "orders"
    PRODUCTS = "products"
    ORDER_ITEMS = "order_items"
    ORDER_PAYMENTS = "order_payments"
    ORDER_REVIEWS = "order_reviews"
    PRODUCT_CATEGORY_NAME_TRANSLATION = "product_category_name_translation"
    GEOLOCATION = "geolocation"


class TransferMethod(Enum):
    SP = "sp"
    ORM = "orm"


class ETLResponse(BaseModel):
    success: bool
    message: str
    rows_affected: int


class ErrorResponse(BaseModel):
    success: bool
    message: str
