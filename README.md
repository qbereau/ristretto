Ristretto
=========

Structure
---------

So far there wasn't a big emphasize on the boot process of the app.
Many classes from AppKit were removed due to their deep reliability on the DOM.
Right now it's **RTApplication** that takes care of the bootstrapping by initializing a concrete **RTRenderer** (SVG or Canvas) and initializing a rootView from which a user-created AppController can add its own subviews.

**RTRenderer** is an abstract class which serves the purpose of :
* Creating a concrete Renderer (SVG or Canvas so far) preferring Canvas over SVG
* Calling layoutSubviews and drawRect of **RTView** classes

**RTRenderer** is used as a Singleton and can be called like this:

> [[RTRenderer sharedRenderer] doSomething]


Instead of using **DOMElements** to manipulate inputs & display elements, we use a **RTElement** which is also an abstract class that needs to be subclassed. Basically a **RTElement** represents an element that we want to see onscreen (such as an Image, a Video, a Label, a Combobox, ...) but it's architecture allows for a flexible way to instantiate the element in question.
For instance, **RTCanvasImageElement** will instantiate a *div* with a *canvas* child. We use the *canvas* to draw the image but we use the *div* to clip the canvas when necessary.
On the other hand, the **RTSVGImageElement** creates a *svg* tag and a *image* child. The *svg* tag allows the clipping of the image if necessary while the *image* displays the actual image.

**Ristretto** redefines its own **RTView**. We tried to use as many Cappuccino classes as possible and in most cases it means that we had to fix them to remove any DOM references and associate these calls with our renderer.

There was lots of changes made to most of Cappuccino files so some functionalities might not work anymore

**RTView** is working with support for 3- and 9-part images

**RTImageView** & **RTVideoView** should be working just fine with support for setScaling and setAlignment.
