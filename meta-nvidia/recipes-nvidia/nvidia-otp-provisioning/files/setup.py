from setuptools import setup, find_packages

setup(
    name="otp-user-area",
    version="0.1",
    url="https://nvidia.com",
    description="OTP User Area creation script.",
    scripts=["otp-user-area.py"],
    packages=find_packages(include=[])
)
