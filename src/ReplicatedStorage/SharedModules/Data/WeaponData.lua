type WeaponData = {
    Name: string;
    Damage: number;
    Price: number;
    Rarity: number;
    ToolPrefab: Tool;
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Weapons = {
        ["Ashrune"] = {
            Name = "Ashrune";
            Damage = 1;
            Price = 0;
            Rarity = 1;
            ToolPrefab = ReplicatedStorage.Assets.Weapons:WaitForChild("Ashrune")
        },

        ["Sturdy Axe"] = {
            Name = "Sturdy Axe";
            Damage = 100;
            Price = 0;
            Rarity = 1;
            ToolPrefab = ReplicatedStorage.Assets.Weapons:WaitForChild("Sturdy Axe")
        }
    },

    RarityList = {

    },
}::{Weapons: {[string]: WeaponData}, RarityList: {[string]: number}}