Docker image for the [EteSync](https://www.etesync.com/) server and web client.

## Usage

Start a Docker container with

```bash
docker run -v <PATH TO DATA DIRECTORY>:/data -p 8080:8080 dsaier/etesync
```

This automatically creates a SQLite database in the given data directory if it does not exist yet. It also creates a user `admin` and prints its random password in the container output.

Go to `localhost:8080/admin` and login with this `admin` user to change its password and create normal users. Then go to `localhost:8080` to use the web client.

Note that this image only supports HTTP. You should use it behind a reverse proxy that supports encrypted connections.
