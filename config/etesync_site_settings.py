import os
import secrets

data_directory = os.environ.get("ETESYNC_DATA_DIRECTORY")
database_file = os.environ.get("ETESYNC_DATABASE_FILE")

ALLOWED_HOSTS = ["*"]
SECRET_FILE = os.path.join(data_directory, "secret.txt")
try:
    open(SECRET_FILE)
except FileNotFoundError:
    with open(SECRET_FILE, 'w') as file:
        file.write(secrets.token_urlsafe(256))

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.path.join(data_directory, database_file)
    }
}
