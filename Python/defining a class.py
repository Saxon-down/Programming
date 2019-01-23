# First CLASS Name
class Name :
    # constructor method - instantiation. Used in creation
    def __init__(self, first, middle, last) :
        self.first = first
        self.middle = middle
        self.last = last
        self.sex = ""
        self.age = ""

    # to-string method
    def __str__(self) :
        # This is used if you print the class object, or pass it to anything expecting a string
        return "NAME: " + " ".join([self.first, self.middle, self.last]) + \
            "\n" + "AGE: " + str(self.age) + \
            "\n" + "GENDER: " + self.sex

    # See also:
    #       __repr__
    #       __eq__, __lt__, __le__ (==, <, <=)
    #           for __gt__, python can just flip the order and use __lt__ instead (if it's defined); same with __ge__
    #       __del__, for deleting once you're done

    def lastFirst(self) :
        return self.last + ", " + self.first + " " + self.middle

    def initials(self) :
        return self.first[0] + self.middle[0] + self.last[0]

    def changeSurname(self, last) :
        self.last = last

    def setSex(self, sex) :
        if sex.lower() == "f" or sex.lower() == "fem" or sex.lower() == "female":
            self.sex = "FEMALE"
        elif sex.lower() == "m" or sex.lower() == "male" == "female":
            self.sex = "MALE"
        else :
            print("ERROR in class Name.setSex: invalid_value=" + sex)
    
    def setAge(self, age) :
        self.age = age

# Second CLASS Student
class Student :
    # fields = name, id, grades(list)
    grades = []
    def __init__(self, name, id) :
        self.name = name
        self.id = id

    def addGrade(self, grade) :
        self.grades.append(grade)
    
    def showGrades(self) :
        return "Grades: " + "".join(str(self.grades))

    def avgGrade(self) :
        return "Average grade: " + str(sum(self.grades) / len(self.grades))

# Third CLASS Shape and derived CLASS Rectangle
class Shape:
    def __init__(self, xcor, ycor) :
        self.x = xcor
        self.y = ycor

    def __str__(self) :
        return "x: " + str(self.x) + ", y: " + str(self.y)

    def move(self, newx, newy) :
        self.x = newx
        self.y = newy

class Rectangle(Shape) :    # Derived class (based on Shape)
    def __init__(self, xcor, ycor, width, height) :
        Shape.__init__(self, xcor, ycor)
        self.width = width
        self.height = height
    
    def __str__(self) :
        retStr = Shape.__str__(self) + "\n"
        retStr += "width: " + str(self.width) + ", height: " + str(self.height)
        return retStr


aName = Name("Mary", "Elizabeth", "Jones")
print("aName is " + str(aName))
print("Initials are : " + str(aName.initials()))
print("School register entry = " + str(aName.lastFirst()))
aName.setAge(32)
aName.setSex("f")
print(str(aName.first) + " is a " + str(aName.age) + "yo " + str(aName.sex))
print(aName)

student1 = Student("Jones", "123")
student1.addGrade(92)
student1.addGrade(78)
student1.addGrade(85)
student1.addGrade(82)
student1.addGrade(96)
print(student1.showGrades())
print(student1.avgGrade())


rec = Rectangle(2,2,4,8)
print(rec)
rec.move(4, 4)
print(rec)