from django.urls import path
from . import views
urlpatterns = [
                path('branchRo/', views.branchRo, name='branchRo'),
                path('branchRw/', views.branchRw, name='branchRw'),
                path('branchNew/', views.branchNew, name='branchNew'),
                path('branchChange/', views.branchChange, name='branchChange'),
                path('branchMove/', views.branchMove, name='branchMove'),
                path('check/<branch>/', views.check, name='check'),
                path('jenkinsAutoAuth/', views.jenkinsAutoAuth, name='jenkinsAutoAuth'),
                path("start_servers/", views.start_servers, name="start_server"),
                path("stop_servers/", views.stop_servers, name="stop_server"),
                path("get_release_records/", views.get_release_records, name="get_release_records"),
                path("get_all_branches/", views.get_all_branches, name="get_all_branches"),
                path('jenkinsAutoAuthRestart/', views.jenkinsAutoAuthRestart, name='jenkinsAutoAuthRestart'),
                path('branchRoNew/', views.branchRoNew, name='branchRoNew'),
                path('branchRwNew/', views.branchRwNew, name='branchRwNew'),
                path('branchRwUG/', views.branchRwUG, name='branchRwUG'),
                path('jenkinsAutoSyProd/', views.jenkinsAutoSyProd, name='jenkinsAutoSyProd'),
                path('posPackage/', views.posPackage, name='posPackage'),
               ]
