export const validateListFoodsQuery = (req, res, next) => {
    const { page, limit } = req.query;
    const details = [];

    const parsedPage = page !== undefined ? Number(page) : null;
    const parsedLimit = limit !== undefined ? Number(limit) : null;

    if (page !== undefined && (!Number.isInteger(parsedPage) || parsedPage <= 0)) {
        details.push({ field: 'page', message: 'page must be a positive integer' });
    }

    if (limit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit <= 0)) {
        details.push({ field: 'limit', message: 'limit must be a positive integer' });
    }

    if ((page !== undefined && limit === undefined) || (page === undefined && limit !== undefined)) {
        details.push({ field: 'pagination', message: 'page and limit must be sent together' });
    }

    if (details.length > 0) {
        return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
    }

    req.foodFilters = {
        page: parsedPage,
        limit: parsedLimit,
    };

    next();
};
