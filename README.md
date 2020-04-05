# TLookupEdit

![TLookupEdit Screenshot](https://github.com/kerm1t/TLookupEdit/blob/master/sample.png)

The component derives from TEdit. It features a custom painted List and Scrollbar.

## Caveat
The Height is limited by MaxHeight property.
Future release shall use CustomControl, to allow the list to exceed the parent from.

## setup


            /        Margin                     Margin
            |               /                   a +---+  YMin
            |               |                   r |   |
            |               |                   g |   |
       Rect |               |              /    i +---+  Y1
            |        Height |       Height |    n | + |  YGrab [Pixel]
            |          Mov  |         Bar  |      |   |
            |               |              \      +---+
            |               |                     |   |
            |               |                     |   |
            |               |                     |   |
            |               \                     +---+  YMax
            \        Margin}
