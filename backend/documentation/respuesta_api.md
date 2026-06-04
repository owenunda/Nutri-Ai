# API Response Contract - NutriAI

This document defines the standard format for NutriAI backend responses.
All responses must follow this structure to maintain consistency in the system.

---

## Successful Response

```json
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

### Fields:

* `success`: Indicates if the operation was successful (true)
* `data`: Contains the requested information
* `message`: Optional descriptive message

---

## Error Response

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": []
  }
}
```

### Fields:

* `success`: Always false
* `message`: Clear explanation of the error
* `error.code`: Internal error code
* `error.details`: List of specific errors (optional)

---

## Error Types

### Validation Error (400)

```json
{
  "success": false,
  "message": "Validation error",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [
      {
        "field": "email",
        "message": "Invalid email"
      }
    ]
  }
}
```

---

### Unauthorized (401)

```json
{
  "success": false,
  "message": "Unauthorized",
  "error": {
    "code": "UNAUTHORIZED"
  }
}
```

---

### Forbidden (403)

```json
{
  "success": false,
  "message": "Access denied",
  "error": {
    "code": "FORBIDDEN"
  }
}
```

---

### Not Found (404)

```json
{
  "success": false,
  "message": "Resource not found",
  "error": {
    "code": "NOT_FOUND"
  }
}
```

---

### Internal Error (500)

```json
{
  "success": false,
  "message": "Internal server error",
  "error": {
    "code": "INTERNAL_ERROR"
  }
}
```

---

## Ejemplos Reales

### Successful Login

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token",
    "user": {
      "id": 1,
      "email": "user@email.com"
    }
  }
}
```

---

### Get Foods

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Chicken",
      "calories": 200,
      "proteins": 25,
      "carbohydrates": 0,
      "fats": 10
    }
  ]
}
```

---

### Error Creating Food

```json
{
  "success": false,
  "message": "Invalid calories",
  "error": {
    "code": "INVALID_CALORIES"
  }
}
```

---

## General Rules

* All responses must have `success`
* Never return errors without `message`
* Don't expose internal server errors
* Maintain consistency across all endpoints
* Use correct HTTP codes

---

## HTTP Codes

| Code | Usage                   |
|------|-------------------------|
| 200  | OK                      |
| 201  | Created                 |
| 400  | Validation error        |
| 401  | Not authenticated       |
| 403  | No permissions          |
| 404  | Not found               |
| 500  | Server error            |

---

## Implementation and Utilities

To maintain this standard across the entire backend, use the provided utilities and classes in the code:

### Response Utilities (`src/utils/response.js`)

In controllers, return responses using helper functions:

```javascript
import { successResponse, errorResponse } from '../utils/response.js';

// Successful response
export const getSomeData = (req, res) => {
  const data = { id: 1, name: "Test" };
  // default status is 200, default message is 'Success'
  return successResponse(res, data, 'Data retrieved successfully'); 
};

// Manual error response (although using AppError and throw is preferred)
export const doSomethingWrong = (req, res) => {
  return errorResponse(res, 'Error message', 'ERROR_CODE', 400, ['Detail 1']);
};
```

### AppError Class (`src/utils/AppError.js`)

To handle operational or business errors, throw (or pass to `next()`) an `AppError` instance and let the global middleware handle sending the response to the client.

```javascript
import { AppError } from '../utils/AppError.js';

export const processAction = (req, res, next) => {
  try {
    const isValid = false;
    if (!isValid) {
      // (message, status, code, details)
      throw new AppError('Validation error', 400, 'VALIDATION_ERROR', ['Required field']);
    }
    return successResponse(res, null, 'Action processed');
  } catch (error) {
    // Pass error to global error handling middleware
    next(error); 
  }
};
```

### Global Error Middleware (`src/middleware/error.middleware.js`)

All errors captured and sent through `next(error)` are processed centrally:
* **Controlled Errors (`AppError`)**: They are formatted and sent with the message, code, and HTTP status defined in the class.
* **Uncontrolled Errors**: They are handled as generic `500` errors.
* **Environments**: In development mode (`NODE_ENV=development`), the stack trace of unhandled errors is automatically included in the `details` array to facilitate debugging. In production, uncontrolled errors always return an opaque and generic error message for security.

---

## Objective

* Consistency in the backend
* Easy frontend integration
* Better error handling
* System scalability
