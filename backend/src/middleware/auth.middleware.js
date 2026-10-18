import jwt from "jsonwebtoken"
import { config } from "../config/env_config.js"
import { AppError } from "../utils/AppError.js"

// El token de un invitado vence con su cuenta: la app avisa en vez de solo
// mandar al login.
const isExpiredGuestToken = (err, token) =>
    err.name === 'TokenExpiredError' && jwt.decode(token)?.isGuest === true

function authenticateToken(requireRoles = []) {
    return (req, res, next) => {
        const authHeader = req.headers.authorization
        const token = authHeader?.split(" ")[1]
        if (!token) {
            return next(new AppError("No token provided", 401, 'UNAUTHORIZED', ['No token provided']))
        }
        jwt.verify(token, config.jwt.secret, (err, user) => {
            if (err) {
                if (isExpiredGuestToken(err, token)) {
                    return next(new AppError('Tu cuenta de invitado venció. Crea una cuenta para seguir usando NutriLife.', 401, 'GUEST_EXPIRED'))
                }
                return next(new AppError("Invalid token", 401, 'UNAUTHORIZED', ['Invalid token']))
            }
            if (requireRoles.length > 0 && !requireRoles.includes(user.role)) {
                return next(new AppError("Unauthorized role", 403, 'FORBIDDEN', ["Unauthorized role"]))
            }
            req.user = user
            next()
        })
    }
}

// Va después de authenticateToken en lo que un invitado no puede hacer:
// comprar o crear una contraseña.
export function rejectGuests(req, res, next) {
    if (req.user?.isGuest) {
        return next(new AppError('Crea una cuenta para hacer esto.', 403, 'GUEST_NOT_ALLOWED'))
    }
    next()
}

export default authenticateToken
