from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://mynote:mynote@localhost:5432/mynote"
    APP_NAME: str = "MyNote API"
    VERSION: str = "0.1.0"

    class Config:
        env_file = ".env"


settings = Settings()
