type PetData = {
    Name: string;
    DamageMultiplier: number;
    Rarity: number;
    ModelPrefab: Model;
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Pets = {
        ["Twice"] = {
            Name = "Twice";
            DamageMultiplier = 1.23;
            Rarity = 1; -- 1 represents Common.
            ModelPrefab = ReplicatedStorage.Assets.Pets:WaitForChild("Twice");
        }
    },

    -- Dummy data.
    RarityList = {
        ["Common"] = 75;
        ["Rare"] = 18.5;
        ["Epic"] = 6;
        ["Legendary"] = 0.5;
    }
}::{Pets: {[string]: PetData}; RarityList: {[string]: number}}