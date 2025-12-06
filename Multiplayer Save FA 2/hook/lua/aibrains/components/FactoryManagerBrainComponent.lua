-- oldFactoryManagerBrainComponent = import("/lua/aibrains/components/FactoryManagerBrainComponent.lua").FactoryManagerBrainComponent

-- FactoryManagerBrainComponent = ClassSimple(oldFactoryManagerBrainComponent) {

--     --- Overrides the original CreateBrainShared method
--     ---@param self FactoryManagerBrainComponent | AIBrain
--     CreateBrainShared = function(self)
--         -- Call original method to retain existing behavior
--         oldFactoryManagerBrainComponent.CreateBrainShared(self)


--         LOG("TODO - If reinitialize army is called, must count factories and set the self.ResearchFactories structure to reflect this. ")
--         -- otherwise this will break the engy mod
--         LOG(repr(self.ResearchFactories))
        
--     end,
-- }
