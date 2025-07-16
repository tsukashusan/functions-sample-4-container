import azure.functions as func
import logging
from dotenv import load_dotenv
import os

load_dotenv()
# Import the `configure_azure_monitor()` function from the
# `azure.monitor.opentelemetry` package.
from azure.monitor.opentelemetry import configure_azure_monitor

# Configure OpenTelemetry to use Azure Monitor with the 
# APPLICATIONINSIGHTS_CONNECTION_STRING environment variable.
logger_namespace = os.environ.get("LOGGER_NAME_SPACE", "CONTAINR_FUNCTIONS")
configure_azure_monitor(
    logger_name=f"{logger_namespace}",  # Set the namespace for the logger in which you would like to collect telemetry for if you are collecting logging telemetry. This is imperative so you do not collect logging telemetry from the SDK itself.
)
logger = logging.getLogger(f"{logger_namespace}")  # Logging telemetry will be collected from logging calls made with this logger and all of it's children loggers.


app = func.FunctionApp()

@app.route(route="HttpExample", auth_level=func.AuthLevel.ANONYMOUS)
def HttpExample(req: func.HttpRequest) -> func.HttpResponse:
    logger.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        logger.info(f"Hello, {name}. This HTTP triggered function executed successfully.")
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        logger.info("This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.")
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )