import jwt from "jsonwebtoken"
import { config } from "../config/env_config.js"
import { AppError } from "../utils/appError.js"


function authenticateToken(requireRoles = []) {
    return (req, res, next) => {
        const authHeader = req.headers.authorization
        const token = authHeader?.split(" ")[1]
        if (!token) {
            throw new AppError("No token provided", 401, 'UNAUTHORIZED', ['No token provided'])
        }
        jwt.verify(token, config.jwt.secret, (err, user) => {
            if (err) {
                throw new AppError("Invalid token", 401, 'UNAUTHORIZED', ['Invalid token'])
            }
            if (requireRoles.length > 0 && !requireRoles.includes(user.role)) {
                throw new AppError("Unauthorized role", 403, 'FORBIDDEN', ["Unauthorized role"])
            }
            req.user = user
            next()
        })
    }
}

export default authenticateToken