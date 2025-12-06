DefaultProjectileWeapon.EconomyDrainThread = function(self)
    local econ = self.EconDrain
    WaitFor(self.EconDrain)

    if self ~= nil and IsDestroyed(self) == false and IsDestroyed(self.unit) == false and self.EconDrain == econ then
        RemoveEconomyEvent(self.unit, self.EconDrain)
        self.EconDrain = nil
    end
end