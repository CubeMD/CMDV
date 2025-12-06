-- LOAD: Add the ability to resume task progress on load

oldEnhanceTask = EnhanceTask
EnhanceTask = Class(oldEnhanceTask) {
	OnCreate = function(self,commandData)
		-- By default, the state of the enhancement (commander upgrades) is not saved in an easily accessible way. This makes it convenient to access.
		self:GetUnit().commandData = commandData
		oldEnhanceTask.OnCreate(self, commandData)
		
		self.LastProgress = commandData.Progress
	end,

	Enhancing = State {
		OnEnterState = function(self)
			local unit = self:GetUnit()

			-- See if we are resuming from a save game, we have saveProgress set.
			if self.CommandData and self.CommandData.Progress then

				LOG("LOAD: Unit resuming enhancement progress from:")
				unit.WorkProgress = self.CommandData.Progress

				-- clear saveProgress so this runs once
				unit.progress = nil
			end
		end,

		TaskTick = oldEnhanceTask.Enhancing.TaskTick,
	},
}