

class Rectangle:
    def __init__(self, width, height) :
        self.width = width	    # Will call the SETTER as soon as it's implemented
        self.height = height	# .. WAS: self._blah = blah
    
    @property	    # Class DECORATOR
    def width(self) :       # GETTER
        return self._width
    
    @width.setter	        # SETTER
    def width(self, width) :
        # Allows us to define setters and getters at a later date, without 
        # breaking existing code (though if it now falls outside of our new
        # requirements it'll generate the ValueError)
        if width <= 0 :
            raise ValueError("Rectangle.width must be positive (trying: {0})".format(width))
            # Nothing after the RAISE statement will be executed! This
            # terminates the entire script.
        else:
            self._width = width

    @property
    def height(self) :      # GETTER
        return self._height

    @height.setter         # GETTER
    def height(self, height) :
        if height <= 0 :
            raise ValueError("Rectangle.height must be positive (trying: {0})".format(height))
        else:
            self._height = height

    def __str__(self) :
        return "Rectangle: width = {0}, height = {1}".format(self.width, self.height)
    
    def __repr__(self) :
        return "Rectangle({0}, {1})".format(self.width, self.height)

    def __eq__(self, other) :
        if isinstance(other, Rectangle) :
            return self.width == other.width and self.height == other.height
        else:
            return False


r1 = Rectangle(10, 20)
print(r1)
r2 = Rectangle(20, 10)
try:
    r2.height = -25
except ValueError as err:
    print("ERROR: r2.height not changed: {0}".format(err))
finally:
    print(r2)
