
TerraFormerT1 = Class()
{
  FlattenTerrain = function(x, z, delta, unit)


    local y_water_min = 1;
    local y_water;
    local y_flatten;
    local y_real;

    local rect_x = x-1;
    local rect_z = z-1;
    local rect_w = 2;
    local rect_h = 2;

    local connect_l = false;
    local connect_r = false;
    local connect_t = false;
    local connect_b = false;

    FlattenMapRect(rect_x, rect_z, rect_w, rect_h, y_water_min);

    y_water = GetSurfaceHeight(x,z);
    y_flatten = y_water + delta;

    LOG("Water Level: " .. y_water);
    LOG("Flatten Level: " .. y_flatten);

    if (delta < 0) then
      for i=1, -2, -1 do
        for j=1, -2, -1 do
          if (GetTerrainHeight(x+i,z+j) > y_water or GetTerrainHeight(x+i+1,z+j+1) > y_water) then
            FlattenMapRect(x+i, z+j, 1, 1, y_water);
          end
        end
      end
    end

    FlattenMapRect(rect_x, rect_z, rect_w, rect_h, y_flatten);
    y_real = GetTerrainHeight(x,z);
    
    if (GetTerrainHeight(x + (rect_w + 2), z) == y_real) then
      connect_r = true
    end

    if (GetTerrainHeight(x - (rect_w + 2), z) == y_real) then
      connect_l = true
    end

    if (GetTerrainHeight(x, z + (rect_h + 2)) == y_real) then
      connect_b = true
    end

    if (GetTerrainHeight(x, z - (rect_h + 2)) == y_real) then
      connect_t = true
    end


    # horizontal connections
    if (connect_r) then
      FlattenMapRect(rect_x + rect_w, rect_z, 2, rect_h, y_flatten);
    end

    if (connect_l) then
      FlattenMapRect(rect_x - 2, rect_z, 2, rect_h, y_flatten);
    end

    # vertical connections
    if (connect_t) then
      FlattenMapRect(rect_x, rect_z - 2, rect_w, 2, y_flatten);
    end

    if (connect_b) then
      FlattenMapRect(rect_x, rect_z + rect_h, rect_w, 2, y_flatten);
    end

    # diagonal connections
    if (connect_b and connect_l) then
      FlattenMapRect(rect_x - 2, rect_z + rect_h, 2, 2, y_flatten);
    end

    if (connect_b and connect_r) then
      FlattenMapRect(rect_x + rect_w, rect_z + rect_h, 2, 2, y_flatten);
    end

    if (connect_t and connect_l) then
      FlattenMapRect(rect_x - 2, rect_z - 2, 2, 2, y_flatten);
    end

    if (connect_t and connect_r) then
      FlattenMapRect(rect_x + rect_w, rect_z - 2, 2, 2, y_flatten);
    end
    
    
    if (y_flatten < y_water) then
      CreateDecal(Vector(x, y_real, z), 0, '/mods/TerraFormerT1_fixedIcons/hook/env/common/decals/tarmacs/TarmacWater_01.dds' , '', 'Albedo', 7.5, 7.5, 1000, 0, unit:GetArmy(), 0)
    else
      CreateDecal(Vector(x, y_real, z), 0, '/mods/TerraFormerT1_fixedIcons/hook/env/common/decals/tarmacs/Tarmac_01.dds' , '', 'Albedo', 6.5, 6.5, 1000, 0, unit:GetArmy(), 0)
    end
    
    return y_water;
  end,
  
  
  Slope = function(x, z, width, height, unit)

    local rect_x = x - width/2;
    local rect_w = x + width/2;
    local rect_z = z - height/2;
    local rect_h = z + height/2;
    
    local y_l = 0;
    local y_r = 0;
    
    if (width > height) then
      y_l = GetTerrainHeight(rect_x-2, z);
      y_r = GetTerrainHeight(rect_w+2, z);
    else
      y_l = GetTerrainHeight(x, rect_z-2);
      y_r = GetTerrainHeight(x, rect_h+2);
    end
    
    local delta = y_r - y_l;
    local step = 0;
    if (width > height) then
      step = delta / width;
    else
      step = delta / height;
    end
    
    if (width > height) then
      for i=0, width, 1 do
        FlattenMapRect(rect_x+i, z-1, 1, height, y_l + step*i);
      end
      CreateDecal(Vector(x, y_l, z), 0, '/mods/TerraFormerT1_fixedIcons/hook/env/common/decals/tarmacs/Tarmac_01.dds' , '', 'Albedo', 19.5, 6.5, 1000, 0, unit:GetArmy(), 0)
    else
      for i=0, height, 1 do
        FlattenMapRect(x-1, rect_z+i, width, 1, y_l + step*i);
      end
      CreateDecal(Vector(x, y_l, z), 0, '/mods/TerraFormerT1_fixedIcons/hook/env/common/decals/tarmacs/Tarmac_01.dds' , '', 'Albedo', 6.5, 19.5, 1000, 0, unit:GetArmy(), 0)
    end
  end
}