from django.shortcuts import render

def home(request):
    """首页视图"""
    return render(request, 'home.html')
