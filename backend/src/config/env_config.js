import dotenv from 'dotenv';
dotenv.config();


const env = process.env

export const config = {
    port: env.PORT,
    db: {
        host: env.HOST_DB,
        user: env.USER_DB,
        password: env.PASS_DB,
        database: env.DATABASE,
        port: env.PORT_DB,
    },
    jwt: {
        secret: env.JWT_SECRET,
    }
}   