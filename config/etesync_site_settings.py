import os

data_directory = os.environ.get("ETESYNC_DATA_DIRECTORY")
database_file = os.environ.get("ETESYNC_DATABASE_FILE")

ALLOWED_HOSTS = ["*"]
SECRET_FILE = os.path.join(data_directory, "secret.txt")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.path.join(data_directory, database_file)
    }
}
