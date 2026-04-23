import { findAllFoods } from './food.repository.js';



export const getFoods = async () => {
    return await findAllFoods();
};

export const getFoodModuleStatus = async () => {
    return {
        module: 'food',
        status: 'running'
    };
};
