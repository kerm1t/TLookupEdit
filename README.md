TLookupEdit

![TLookupEdit Screenshot](https://github.com/kerm1t/TLookupEdit/blob/master/sample.png)

{ Scrollbar, the moveable area is smaller than the full Scrollbar area, due to margin

            /    Margin                         Margin
            |               /                   a +---+  YMin
            |               |                   r |   |
            |               |                   g |   |
    Rect    |               |              /    i +---+  Y1
            |    Height     |    Height    |    n | + |  YGrab [Pixel]
            |      Mov      |      Bar     |      |   |
            |               |              \      +---+
            |               |                     |   |
            |               |                     |   |
            |               |                     |   |
            |               \                     +---+  YMax
            \    Margin
}
