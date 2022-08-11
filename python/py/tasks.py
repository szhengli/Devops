from .celery import app

@app.task
def add(x,y):
    return x + y

@app.task
def minus(x,y):
    return x - y