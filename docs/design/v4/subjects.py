"""What each coloring page shows, as prompts for sd_draw.py.

Every subject is drawn alone, whole, on plain light blue (so white fur and
white cars still stand out), without a shadow, so it can be cut out
and turned into a coloring page (to_page.py). Animals and vehicles face
sideways; flat insects are seen from above.
"""

STYLE = ("realistic children's encyclopedia illustration, natural colors, clean shapes, "
         "isolated on a plain flat light blue background, no shadow")
NEGATIVE = ("text, letters, watermark, signature, frame, border, blurry, lowres, deformed, extra legs, extra limbs, "
            "missing legs, cropped, cut off, two heads, people, person, group, many, background scenery, landscape, "
            "shadow, floor, ground, platform, pedestal, base, grass patch, rock, white background")

SUBJECTS = {
    # the zoo
    "elephant": "side view of an african elephant walking, full body with trunk and tusks",
    "giraffe": "side view of a giraffe standing, full body with long neck and legs",
    "lion": "side view of a male lion standing, full body with a big mane",
    "panda": "a giant panda sitting and holding bamboo, full body, front view",
    "zebra": "side view of a zebra standing, full body with black and white stripes",
    "monkey": "side view of a cute monkey sitting, full body with long tail",
    # the aquarium
    "clownfish": "side view of one clownfish, bright orange with three white bands edged in black, whole fish in the middle of the picture",
    "octopus": "a friendly octopus with eight curly tentacles, front view, full body",
    "turtle": "side view of a green sea turtle with its flippers spread, full body, shell and head clearly visible",
    "whale": "side view of a humpback whale, full body",
    "jellyfish": "a pink jellyfish with a solid opaque round bell and long wavy tentacles, front view, full body, even flat lighting",
    "crab": "a red crab with big claws, front view, full body",
    # the dinosaur park
    "trex": "side view of a tyrannosaurus rex walking, full body",
    "triceratops": "side view of a triceratops dinosaur figurine, a huge round bony frill shield behind its head, three horns, beak-like mouth, four sturdy legs, green, full body",
    "brachiosaurus": "side view of one brachiosaurus dinosaur standing on four pillar legs, a single small head on one very long upright neck, a long tail, gray green skin, full body",
    "stegosaurus": "side view of a stegosaurus dinosaur walking on four legs, a row of big diamond shaped orange plates along its back, four spikes at the tail tip, small head, green skin, full body",
    "pterosaur": "side view of a pteranodon flying with its wings spread wide, a long pointed beak and a crest on its head, brown and orange, full body",
    "babyDino": "a cute green baby dinosaur standing next to a cracked white egg shell, side view, even flat lighting, no glow",
    # the transport museum
    "fireTruck": "side view of a red fire truck with a ladder on top, the whole truck in the middle of the picture with space around it",
    "policeCar": "side view of a white police car with blue lights on the roof, the whole car in the middle of the picture with space around it",
    "ambulance": "side view of a white ambulance van with a red cross and red stripes, the whole van in the middle of the picture with space around it",
    "bus": "side view of a city bus, full vehicle",
    "scooter": "side view of a small motor scooter, full vehicle",
    "train": "side view of a small red steam locomotive engine alone, no carriages, the whole engine in the middle of the picture with space around it",
    "airplane": "side view of a passenger airplane flying, full plane",
    "helicopter": "side view of a yellow helicopter flying, full helicopter",
    # the botanical garden
    "sunflower": "a single tall sunflower plant with leaves, whole plant",
    "tulip": "a single red tulip flower with leaves, whole plant",
    "cactus": "a green saguaro cactus with arms in a small pot",
    "lotus": "side view of a single pink lotus flower in bloom on a tall green stem, one round lotus leaf on its own stem beside it, no water",
    "strawberry": "a strawberry plant with green leaves, small white flowers and three ripe red strawberries hanging down, whole plant",
    "rose": "a single red rose flower on a stem with leaves",
    # the insect museum
    "butterfly": "top view of a colorful butterfly with wings spread open",
    "ladybug": "top view of a red ladybug with black spots",
    "bee": "side view of a honey bee flying",
    "beetle": "side view of a japanese rhinoceros beetle insect, shiny dark brown shell, six thin jointed legs, one long forked horn on its head, a bug",
    "dragonfly": "top view of a dragonfly with four wings spread",
    "mantis": "side view of a green praying mantis",
}


def prompt(cid):
    return f"{SUBJECTS[cid]}, {STYLE}"
