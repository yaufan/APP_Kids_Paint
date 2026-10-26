"""Vehicle coloring pages for the transport museum (交通車館).

All are Twemoji (CC BY 4.0, see twemoji.py) turned into line art, facing
right like the animals, without the rails the trains stand on (the scene
has its own track).
"""
from animals import tw_page


def fire_truck(**k):
    return tw_page("1f692", **k)


def police_car(**k):
    return tw_page("1f693", **k)


def ambulance(**k):
    return tw_page("1f691", **k)


def bus(**k):
    return tw_page("1f68c", **k)


def scooter(**k):
    return tw_page("1f6f5", **k)


def train(**k):
    return tw_page("1f682", drop=(0,), **k)


def airplane(**k):
    return tw_page("2708", flip=False, **k)


def helicopter(**k):
    return tw_page("1f681", **k)


VEHICLES = {
    "fireTruck": ("transport", fire_truck), "policeCar": ("transport", police_car), "ambulance": ("transport", ambulance),
    "bus": ("transport", bus), "scooter": ("transport", scooter), "train": ("transport", train),
    "airplane": ("transport", airplane), "helicopter": ("transport", helicopter),
}
