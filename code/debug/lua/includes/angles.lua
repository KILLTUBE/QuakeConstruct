FIRST = 1;
SECOND = 2;
THIRD = 3;
FOURTH = 4;

function getDeltaAngle3(angle1, angle2)
	angle1 = normalizeAngle3(angle1)
	angle2 = normalizeAngle3(angle2)
	local ang = Vector()
	ang.x = getDeltaAngle(angle2.x, angle1.x)
	ang.y = getDeltaAngle(angle2.y, angle1.y)
	ang.z = getDeltaAngle(angle2.z, angle1.z)
	return ang
end

function normalizeAngle3(angle)
	local ang = Vector()
	ang.x = normalizeAngle(angle.x)
	ang.y = normalizeAngle(angle.y)
	ang.z = normalizeAngle(angle.z)
	return ang
end
--Returns a number representing the delta between 2 angles
function getDeltaAngle(angle1, angle2)
	angle2 = normalizeAngle(angle2);
	angle1 = normalizeAngle(angle1);
	q1 = getQuadrant(angle1);
	q2 = getQuadrant(angle2);
	if(q1 == q2) then
		return angle2 - angle1;
	elseif(q1 == FIRST && q2 == FOURTH) then
		return angle2 - angle1 - 360.0;
	elseif(q1 == FOURTH && q2 == FIRST) then
		return 360 + angle2 - angle1;
	elseif(math.abs(q1-q2) == 1) then
		return angle2 - angle1;
	elseif(math.abs(q1-q2) == 2) then
		if((q1 == FIRST && q2 == THIRD) || (q1 == SECOND && q2 == FOURTH)) then
			delta = angle2 - angle1;
			if(delta < 180.0) then
				return delta;
			else 
				return delta - 360;
			end
		elseif((q2 == FIRST && q1 == THIRD) || (q2 == SECOND && q1 == FOURTH)) then
			delta = angle1 - angle2;
			if(delta < 180.0) then
				return -delta;
			else 
				return 360.0 - delta;
			end
		end
	end
	return 0.0;
end
	
function getQuadrant(angle)
	if(angle >=0 && angle < 90.0) then return FIRST; end
	if(angle >=90.0 && angle < 180.0) then return SECOND; end
	if(angle >=180.0 && angle < 270.0) then return THIRD; end
	return FOURTH;
end
	
function normalizeAngle(angle)
	while (angle >= 360.0) do 
		angle = angle - 360.0;
	end
	while (angle < 0.0) do
		angle = angle + 360.0;
	end
	return angle;
end
