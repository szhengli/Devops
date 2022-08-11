from celery import Celery


app = Celery('py', include=["py.tasks"])
app.config_from_object("py.celeryconfig")


if __name__ == "__main__":
    app.start()