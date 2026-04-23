import dotenv from 'dotenv';
dotenv.config();


const env = process.env

export const config = {
    node_env: env.NODE_ENV,
    port: env.PORT,
    db: {
        host: env.HOST_DB,
        user: env.USER_DB,
        password: env.PASS_DB,
        name: env.NAME_DB,
        port: env.PORT_DB,
    },
    jwt: {
        secret: env.JWT_SECRET,
    }
}   