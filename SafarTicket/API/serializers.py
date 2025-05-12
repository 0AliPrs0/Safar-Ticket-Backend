from rest_framework import serializers

class UserSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    email = serializers.EmailField(allow_null=True)
    phone_number = serializers.CharField(allow_null=True)
    user_type = serializers.CharField()
    city_id = serializers.IntegerField()
    registration_date = serializers.DateTimeField()
    account_status = serializers.CharField()
