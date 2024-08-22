from django.apps import AppConfig
from django.db.utils import OperationalError, ProgrammingError
from django.core.exceptions import AppRegistryNotReady

class BlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'blog'

    def ready(self):
        try:
            from django.contrib.auth.models import User
            import os

            username = os.getenv('DJANGO_SUPERUSER_USERNAME')
            email = os.getenv('DJANGO_SUPERUSER_EMAIL')
            password = os.getenv('DJANGO_SUPERUSER_PASSWORD')

            if not User.objects.filter(username=username).exists():
                User.objects.create_superuser(username=username, email=email, password=password)
                print(f'Superuser {username} created successfully.')
            else:
                print(f'Superuser {username} already exists.')
        except (OperationalError, ProgrammingError, AppRegistryNotReady):
            print('Database is not ready yet, skipping superuser creation.')

