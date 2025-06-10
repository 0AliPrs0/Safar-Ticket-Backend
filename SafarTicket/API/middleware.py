from .utils.jwt import verify_jwt

class JWTMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        auth_header = request.headers.get('Authorization', None)
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            user_info = verify_jwt(token)
            if user_info:
                request.user_info = user_info

        response = self.get_response(request)
        return response