---
description: How to update the backend on Digital Ocean
---

This workflow describes the manual process to update your Serverpod backend running on a Digital Ocean Droplet using Docker Compose.

1.  **Push your changes to GitHub**
    Make sure all your local changes are committed and pushed to the `main` (or relevant) branch.
    ```bash
    git add .
    git commit -m "Update backend"
    git push origin main
    ```

2.  **Connect to your Droplet**
    SSH into your Digital Ocean server. Replace `user` and `your_droplet_ip` with your actual credentials.
    ```bash
    ssh user@your_droplet_ip
    ```

3.  **Navigate to the project directory**
    Go to the folder where your backend code is cloned.
    ```bash
    cd /path/to/zifra_backend
    ```

4.  **Pull the latest changes**
    Get the updates from GitHub.
    ```bash
    git pull origin main
    ```

5.  **Rebuild and Restart Containers**
    Navigate to the server directory and run Docker Compose.
    ```bash
    cd zifra_backend_server
    docker compose -f deploy/docker-compose.prod.yaml up -d --build
    ```
    *   `-f deploy/docker-compose.prod.yaml`: Specifies the production compose file.
    *   `up`: Creates and starts containers.
    *   `-d`: Detached mode (runs in background).
    *   `--build`: Forces a rebuild of the images to include your code changes.

6.  **Verify Status**
    Check if the containers are running correctly.
    ```bash
    docker compose -f deploy/docker-compose.prod.yaml ps
    ```
    You can also follow the logs to ensure everything started up fine:
    ```bash
    docker compose -f deploy/docker-compose.prod.yaml logs -f
    ```

7.  **Apply Database Migrations (If needed)**
    If you made changes to the database schema, the Serverpod container usually handles migrations on startup, but verify logs to be sure.
