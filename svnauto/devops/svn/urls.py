from django.urls import path
from . import views
urlpatterns = [
                path('branchRo/', views.branchRo, name='branchRo'),
                path('branchRw/', views.branchRw, name='branchRw'),
                path('branchNew/', views.branchNew, name='branchNew'),
                path('branchChange/', views.branchChange, name='branchChange'),
                path('branchMove/', views.branchMove, name='branchMove'),
                path('check/<branch>/', views.check, name='check'),
                path('jenkinsAutoAuth/', views.jenkinsAutoAuth, name='jenkinsAutoAuth')
               ]
