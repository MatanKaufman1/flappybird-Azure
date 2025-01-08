"""
Flask web application for user authentication and score tracking.

This application provides endpoints for user registration, authentication,
score submission, and leaderboard functionality. It uses Azure SQL Database
for data persistence and implements session-based authentication.

Module dependencies:
    flask: Web framework for handling HTTP requests and responses
    dotenv: Environment variable management
    flask_cors: Handle Cross-Origin Resource Sharing
    pyodbc: Database connectivity for Azure SQL
    logging: Application logging functionality
    logging_loki: Grafana Loki logging integration
    os: Operating system interface for environment variables
    sys: System-specific parameters and functions

Environment Variables Required:
    AZURE_SQL_SERVER: Azure SQL Server hostname
    AZURE_SQL_DATABASE: Database name
    AZURE_SQL_USERNAME: Database username
    AZURE_SQL_PASSWORD: Database password

"""
from flask import (
    Flask,
    request,
    jsonify,
    send_from_directory,
    session,
    redirect,
    url_for,
)
from dotenv import load_dotenv
from flask_cors import CORS
import pyodbc
import logging
from logging_loki import LokiHandler
import os
import sys

app = Flask(__name__, static_url_path="")


LOGIN_HTML = "login.html"
INTERNAL_SERVER_ERROR_MESSAGE = "Internal server error"

app.config["SESSION_TYPE"] = "filesystem"
app.config["SECRET_KEY"] = "your-secret-key"
#Session(app)
CORS(app)

load_dotenv('azure-login.env')
AZURE_SQL_SERVER = os.getenv("AZURE_SQL_SERVER")
AZURE_SQL_DATABASE = os.getenv("AZURE_SQL_DATABASE")
AZURE_SQL_USERNAME = os.getenv("AZURE_SQL_USERNAME")
AZURE_SQL_PASSWORD = os.getenv("AZURE_SQL_PASSWORD")

connection_string = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={AZURE_SQL_SERVER};"
    f"DATABASE={AZURE_SQL_DATABASE};"
    f"UID={AZURE_SQL_USERNAME};"
    f"PWD={AZURE_SQL_PASSWORD}"
)
conn = pyodbc.connect(connection_string)
cursor = conn.cursor()

def initialize_database():
    """
    Initialize the database by creating necessary tables if they don't exist.
    
    Creates two tables:
    - users: Stores user authentication information
    - scores: Stores user game scores
    """

    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
    CREATE TABLE users (
        id INT IDENTITY PRIMARY KEY,
        username NVARCHAR(255) NOT NULL UNIQUE,
        password NVARCHAR(255) NOT NULL
    )
    """)
    cursor.execute("""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='scores' AND xtype='U')
    CREATE TABLE scores (
        id INT IDENTITY PRIMARY KEY,
        username NVARCHAR(255) NOT NULL,
        score FLOAT NOT NULL
    )
    """)
    conn.commit()

initialize_database()


@app.route("/")
def serve_index():
      """
    Serve the main index page if user is authenticated, otherwise redirect to login.

    Returns:
        Response: Either the index page or a redirect to the login page
    """

    if "username" not in session:
        return redirect(url_for("login"))
    return send_from_directory("static", "index.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    """
    Handle user registration.

    POST Parameters:
        username (str): The desired username (alphabetic characters only)
        password (str): The user's password

    Returns:
        Response: JSON response indicating success or failure
        - 200: Registration successful
        - 400: Invalid username
        - 500: Internal server error
    """

    if request.method == "POST":
        try:
            data = request.json
            username = data.get("username")
            password = data.get("password")

            if not username or username.strip() == "":
                return jsonify({"error": "Username is required"}), 400
            if not username.strip().isalpha():
                return jsonify({"error": "Username must contain only letters"}), 400
            
            cursor.execute("SELECT username FROM users WHERE username = ?", username)
            user = cursor.fetchone()
            if not user:
                cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)", username, password)
                conn.commit()
                session["username"] = username
                return jsonify({"message": "Registration successful!"}), 200
            else:
                return jsonify({"message": "Username already exists"}), 200

        except Exception as e:
            app.logger.error(f"Unexpected error during registration: {e}")
            return jsonify({"error": "Internal server error"}), 500
    return send_from_directory("static", login.html)


@app.route("/login", methods=["GET", "POST"])
def login():
    """
    Handle user authentication.

    POST Parameters:
        username (str): The user's username
        password (str): The user's password

    Returns:
        Response: JSON response indicating success or failure
        - 200: Login successful with redirect URL
        - 400: Invalid credentials
        - 500: Internal server error
    """

    if request.method == "POST":
        try:
            data = request.json
            username = data.get("username")
            password = data.get("password")

            cursor.execute("SELECT password FROM users WHERE username = ?", username)
            user = cursor.fetchone()

            if user == None:
                return jsonify({"error": "Username must be registerd"}), 400
            stored_password = user[0]
            if password == stored_password:
                session["username"] = username
                app.logger.info(f"{username} - Login success from Loki.")
                return jsonify({"message": "Login successful!", "redirect_url": "/"}), 200
            else:
                return jsonify({"error": "The password is wrong"}), 400


        except Exception as e:
            app.logger.error(f"Unexpected error during login: {e}")
            return jsonify({"error": INTERNAL_SERVER_ERROR_MESSAGE}), 500

    return send_from_directory("static", "login.html")


@app.route("/logout", methods=["POST"])
def logout():
    """
    Handle user logout by clearing the session.

    Returns:
        Response: Redirect to login page or error response
        - 200: Successful logout
        - 500: Internal server error
    """
    try:
        session.clear()
        return send_from_directory("static", LOGIN_HTML)
    except Exception as e:
        app.logger.error(f"Unexpected error during logout: {e}")
        return jsonify({"error": INTERNAL_SERVER_ERROR_MESSAGE}), 500


@app.route("/submit-score", methods=["POST"])
def submit_score():
    """
    Submit a new score for the authenticated user.

    The score is only updated if it's higher than the user's existing score.

    POST Parameters:
        score (float): The score to submit

    Returns:
        Response: JSON response indicating success or failure
        - 200: Score submitted successfully
        - 400: Invalid score data
        - 401: User not authenticated
        - 500: Internal server error
    """
    if "username" not in session:
        return jsonify({"error": "Unauthorized"}), 401
    try:
        data = request.json
        score = data.get("score")
        if not isinstance(score, (int, float)):
            return jsonify({"error": "Invalid data"}), 400
        
        cursor.execute("SELECT score FROM scores WHERE username = ?", session["username"])
        existing_score = cursor.fetchone()

        if existing_score:
            # Update score only if the new score is higher
            if score > existing_score[0]:
                cursor.execute(
                    "UPDATE scores SET score = ? WHERE username = ?",
                    (score, session["username"])
                )
        else:
            # Insert a new record if no existing score is found
            cursor.execute(
                "INSERT INTO scores (username, score) VALUES (?, ?)",
                (session["username"], score)
            )

            # Commit changes to the database
        conn.commit()

        return jsonify({"message": "Score submitted successfully!"}), 200

    except Exception as e:
        app.logger.error(f"Unexpected error during score submission: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/leaderboard", methods=["GET"])
def get_leaderboard():
    """
    Retrieve the top 20 scores from all users.

    Returns:
        Response: JSON response containing leaderboard data or error
        - 200: List of top 20 scores with usernames
        - 500: Internal server error
    """
    try:
        cursor.execute("SELECT TOP 20 username, score FROM scores ORDER BY score DESC")
        top_scores = cursor.fetchall()

        leaderboard = [{"username": row[0], "score": row[1]} for row in top_scores]

        return jsonify(leaderboard), 200

    except Exception as e:
        app.logger.error(f"Unexpected error while fetching leaderboard: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/health", methods=["GET"])
def health_check():
      """
    Check the health status of the application.

    Returns:
        Response: JSON response indicating application health
        - 200: Application is healthy
        - 500: Application is unhealthy with error details
    """

    try:
        return jsonify({"status": "UP"}), 200
    except Exception as e:
        return jsonify({"status": "DOWN", "error": str(e)}), 500


if __name__ == "__main__":
    try:
        app.run(debug=True, host="0.0.0.0", port=3000)
    except Exception as e:
        app.logger.error(f"Unexpected error during application startup: {e}")

