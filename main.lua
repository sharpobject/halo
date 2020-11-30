require"class"
require"queue"
local pi,sin,cos = math.pi,math.sin,math.cos
local floor = math.floor

local img, pxs
local dxs = {-1,1, 0,0}
local dys = { 0,0,-1,1}
local circle = {}

for i=0,pi*2,pi/10000 do
  local r = 55
  local x,y = sin(i),cos(i)
  x = floor(x*r+.5)
  y = floor(y*r+.5)
  circle[x] = circle[x] or {}
  circle[x][y] = true
end

local cx, cy = {},{}
for x,ys in pairs(circle) do
  for y in pairs(ys) do
    cx[#cx+1] = x
    cy[#cy+1] = y
  end
end
local nc = #cx
print(nc.." circledog")

function imagedata_to_file(imagedata, filename)
  local data = imagedata:encode("png")
  local file = io.open(filename, "w")
  local sofar = 0
  local chunk_sz = 64*1024
  while sofar < data:getSize() do
    collectgarbage("collect")
    print("copying !!! "..sofar)
    local chunk = chunk_sz
    local upper_bound = sofar + chunk
    if upper_bound > data:getSize() then
      chunk = data:getSize() - sofar
    end
    local view = love.data.newDataView(data, sofar, chunk)
    file:write(view:getString())
    sofar = sofar + chunk
  end
  file:close()
end

function love.load()
  img = love.image.newImageData("input.png")
  pxs = {}
  img:mapPixel(function(x,y,r,g,b,a)
    pxs[x] = pxs[x] or {}
    pxs[x][y] = {r,g,b,a}
    return r,g,b,a
  end)
  local wall = {}
  local nwall = {}
  local seen = {}
  local w = #pxs
  local h = #pxs[0]
  for x=0,w do
    wall[x] = {}
    nwall[x] = {}
    seen[x] = {}
    for y=0,h do
      wall[x][y] = pxs[x][y][4] > .5
    end
  end
  print"wall expansion"
  local st = love.timer.getTime()
  for x=0,w do
    for y=0,h do
      if wall[x][y] then
        nwall[x][y] = true
        for i=1,nc do
          local nx,ny = x+cx[i], y+cy[i]
          if not (nx < 0 or ny < 0 or nx > w or ny > h) then
            nwall[nx][ny] = true
          end
        end
      end
    end
  end
  local et = love.timer.getTime()
  print("took "..math.floor((et-st)*1000000)/1000)
  print"wall expansion done"
  wall = nwall
  local xq = Queue()
  local yq = Queue()
  xq:push(0)
  yq:push(0)
  print("bfs time!")
  local st = love.timer.getTime()
  while xq:len() > 0 do
    local x,y = xq:pop(),yq:pop()
    if seen[x][y] or wall[x][y] then
      goto continue
    end
    seen[x][y] = true
    for i=1,4 do
      local dx, dy = dxs[i], dys[i]
      local nx, ny = x+dx, y+dy
      if not (nx < 0 or ny < 0 or nx > w or ny > h) then
        xq:push(nx)
        yq:push(ny)
      end
    end
    ::continue::
  end
  local et = love.timer.getTime()
  print("took "..math.floor((et-st)*1000000)/1000)
  print("bfs done!")
  local canvas = love.graphics.newCanvas(w,h)
  love.graphics.setCanvas(canvas)
  love.graphics.rectangle("fill",0,0,w+1,h+1)
  love.graphics.draw(love.graphics.newImage(img))
  love.graphics.setCanvas()
  img = canvas:newImageData()
  img:mapPixel(function(x,y,r,g,b,a)
    if seen[x][y] then
      return 0,0,0,0
    else
      return r,g,b,a
    end
  end)
  imagedata_to_file(img, "cheeky.png")
  draw_img = love.graphics.newImage(img)
  img:mapPixel(function(x,y,r,g,b,a)
    if seen[x][y] then
      for i=1,4 do
        local nx,ny = x+dxs[i],y+dys[i]
        if not (nx < 0 or ny < 0 or nx > w or ny > h) then
          if not seen[nx][ny] then
            return 1,0,0,1
          end
        end
      end
    end
    return 1,1,1,1
  end)
  imagedata_to_file(img, "outline.png")
end

function love.draw()
  love.graphics.scale(1/3)
  love.graphics.draw(draw_img)
end