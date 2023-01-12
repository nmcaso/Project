function z = CoeffCalc(xNN,yNN,x0,y0,R,triangle)
%COEFFCALC will calculate the corresponding coefficients for each of the
%nearest neighbors from TriangleInterp

global GAM

    %intersection angles (Place for improvement, numerical error will be in
    %assuming the arc intersects the triangle at one of the vertices)
    ang(1) = atan((xNN(1)-x0)/(yNN(1)-y0));
    ang(2) = atan((xNN(2)-x0)/(yNN(2)-y0));
    ang(3) = atan((xNN(3)-x0)/(yNN(3)-y0));

    theta1 = min(ang);
    theta2 = max(ang);

    switch triangle %Analytic derivative of the interpolated triangle
        case 1 %bottom right triangle
            if theta1 == ang(1)
                dtdr1 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta1 == ang(2)
                dtdr1 = (x1-x0)/(R^2*cos(theta1));
            elseif theta1 == ang(3)
                dtdr1 = (y0-y1)/(R^2*sin(theta1));
            end

            if theta2 == ang(2)
                dtdr2 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta2 == ang(1)
                dtdr2 = (x1-x0)/(R^2*sin(theta1));
            elseif theta2 == ang(3)
                dtdr2 = (y0-y1)/(R^2*cos(theta1));
            end
        case 2 %top right triangle
            if theta1 == ang(3)
                dtdr1 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta1 == ang(2)
                dtdr1 = (x1-x0)/(R^2*cos(theta1));
            elseif theta1 == ang(1)
                dtdr1 = (y0-y1)/(R^2*sin(theta1));
            end

            if theta2 == ang(1)
                dtdr2 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta2 == ang(2)
                dtdr2 = (x1-x0)/(R^2*sin(theta1));
            elseif theta2 == ang(3)
                dtdr2 = (y0-y1)/(R^2*cos(theta1));
            end
        case 3 %bottom left triangle
            if theta1 == ang(1)
                dtdr1 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta1 == ang(2)
                dtdr1 = (x1-x0)/(R^2*cos(theta1));
            elseif theta1 == ang(3)
                dtdr1 = (y0-y1)/(R^2*sin(theta1));
            end

            if theta2 == ang(3)
                dtdr2 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta2 == ang(2)
                dtdr2 = (x1-x0)/(R^2*sin(theta1));
            elseif theta2 == ang(1)
                dtdr2 = (y0-y1)/(R^2*cos(theta1));
            end
        case 4 %top left triangle
            if theta1 == ang(3) %diagonal
                dtdr1 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta1 == ang(2) %vertical
                dtdr1 = (x1-x0)/(R^2*cos(theta1));
            elseif theta1 == ang(1) %horizontal
                dtdr1 = (y0-y1)/(R^2*sin(theta1));
            end

            if theta2 == ang(2)
                dtdr2 = (y0+y1-x0)/(sqrt(2)*R^2*sin(theta1+pi/4));
            elseif theta2 == ang(3)
                dtdr2 = (x1-x0)/(R^2*sin(theta1));
            elseif theta2 == ang(1)
                dtdr2 = (y0-y1)/(R^2*cos(theta1));
            end
    end
    
    %Determinants seperated by z Coefficient (pixel number)
    %A = (y2*z3)+(y1*z2)+(y3*z1)-(z1*y2)-(z2*y3)-(z3*y1);
    A1 = yNN(3)-yNN(2); %z1
    A2 = yNN(1)-yNN(3); %z2
    A3 = yNN(2)-yNN(1); %z3

    %B = (x1*z3)+(x3*z2)+(z1*x2)-(x2*z3)-(x3*z1)-(x1*z2);
    B1 = xNN(2)-xNN(3); %z1
    B2 = xNN(3)-xNN(1); %z2
    B3 = xNN(1)-xNN(2); %z3

    C = det([xNN(1), yNN(1), 1; xNN(2), yNN(2), 1; xNN(3), yNN(3), 1]);

    %D = (x1*y2*z3)+(x2*y3*z1)+(x3*y1*z2)-(x3*y2*z1)-(x2*y1*z3)-(x1*y3*z2);
    D1 = xNN(2)*yNN(3)-xNN(3)*yNN(2); %z1
    D2 = xNN(3)*yNN(1)-xNN(1)*yNN(3); %z2
    D3 = xNN(1)*yNN(2)-xNN(2)*yNN(1); %z3

    %Parts of eqn. 11 grouped by coefficient z1
    g11 = dtdr1*(A1*(x0+R*cos(theta1))+B1*(y0+R*sin(theta1))+D1); %d theta1
    g12 = dtdr2*(A1*(x0+R*cos(theta2))+B1*(y0+R*sin(theta2))+D1); %d theta2
    g13 = A1*(sin(theta1)-sin(theta2)) + B1*(cos(theta2)-cos(theta1));
    %infinite catch
    if isinf(g11-g12-g13) || isnan(g11-g12-g13)
        g11 = 0;
        g12 = 0;
        g13 = 0;
    end
    
    %Parts of eqn. 11 grouped by coefficient z2
    g21 = dtdr1*(A2*(x0+R*cos(theta1))+B2*(y0+R*sin(theta1))+D2); %d theta1
    g22 = dtdr2*(A2*(x0+R*cos(theta2))+B2*(y0+R*sin(theta2))+D2); %d theta2
    g23 = A2*(sin(theta1)-sin(theta2)) + B2*(cos(theta2)-cos(theta1));
    %infinite catch
    if isinf(g21-g22-g23) || isnan(g21-g22-g23)
        g21 = 0;
        g22 = 0;
        g23 = 0;
    end
    
    %Parts of eqn. 11 grouped by coefficient z2
    g31 = dtdr1*(A3*(x0+R*cos(theta1))+B3*(y0+R*sin(theta1))+D3); %d theta1
    g32 = dtdr2*(A3*(x0+R*cos(theta2))+B3*(y0+R*sin(theta2))+D3); % d theta2
    g33 = A3*(sin(theta1)-sin(theta2)) + B3*(cos(theta2)-cos(theta1));
    %infinite catch
    if isinf(g31-g32-g33) || isnan(g31-g32-g33)
        g31 = 0;
        g32 = 0;
        g33 = 0;
    end
    
    z(1) = ((GAM/4/pi)*(1/C)*(g11-g12-g13));
    z(2) = ((GAM/4/pi)*(1/C)*(g21-g22-g23));
    z(3) = ((GAM/4/pi)*(1/C)*(g31-g32-g33));
end
