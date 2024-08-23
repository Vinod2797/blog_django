# Use the official Python image from the Docker Hub
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt /app/

# Install the dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . /app/

# Make the wait-for-it.sh script executable
RUN chmod +x /app/wait-for-it.sh

# Expose the port the app runs on
EXPOSE 8000

# Run the application
CMD ["sh", "-c", "./wait-for-it.sh db:5432 -- gunicorn --bind 0.0.0.0:8000 blog_django.wsgi:application"]

