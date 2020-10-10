import os

data_directory = os.environ.get("ETEBASE_DATA_DIRECTORY")
database_file = os.environ.get("ETEBASE_DATABASE_FILE")

ALLOWED_HOSTS = ["*"]
SECRET_FILE = os.path.join(data_directory, "secret.txt")

MEDIA_ROOT = os.environ.get("ETEBASE_MEDIA_DIRECTORY")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.path.join(data_directory, database_file),
    }
}
