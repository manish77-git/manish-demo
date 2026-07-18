/**
 * DrawBattle Prompt Bank
 * 5,000+ unique prompts organized by 15 categories and 3 difficulty tiers.
 */

import logger from '../utils/logger.js';

// Base word banks for 15 categories
const categoryData = {
  'Animals': {
    easySubjects: ['cat', 'dog', 'rabbit', 'hamster', 'lion', 'tiger', 'bear', 'panda', 'fox', 'wolf', 'deer', 'koala', 'kangaroo', 'monkey', 'cow', 'pig', 'sheep', 'chicken', 'duck', 'horse', 'mouse', 'frog', 'turtle', 'elephant', 'giraffe', 'zebra', 'hippo', 'rhino', 'owl', 'penguin'],
    easyAdjectives: ['cute', 'happy', 'fluffy', 'sleepy', 'tiny', 'playful', 'chubby', 'friendly', 'funny', 'little', 'golden', 'lazy'],
    mediumSubjects: ['squirrel', 'racoon', 'hedgehog', 'otter', 'beaver', 'sloth', 'owl', 'parrot', 'peacock', 'flamingo', 'dolphin', 'whale', 'octopus', 'crab', 'seal', 'crocodile', 'kangaroo', 'bat', 'badger', 'platypus'],
    mediumActions: ['eating a snack', 'climbing a tree', 'sleeping on a rug', 'playing with a ball', 'splashing in water', 'chasing a bug', 'peeking out of a box', 'stretching its legs', 'sitting on a fence', 'holding a flower'],
    mediumLocations: ['in a sunny park', 'in a cozy backyard', 'near a quiet pond', 'under a rainbow', 'in a green meadow', 'inside a hollow log', 'on a wooden porch', 'by a sandy beach', 'under a shady tree', 'in the deep forest'],
    hardSubjects: ['a majestic bald eagle', 'a stealthy black panther', 'a giant humpback whale', 'a mother grizzly bear with cubs', 'a wise old sea turtle', 'a herd of running wild horses', 'a family of emperor penguins', 'a colorful chameleon', 'a pack of howling wolves', 'a playful sea otter'],
    hardActions: ['hunting for fish in the mist', 'soaring high through storm clouds', 'leaping majestically out of ocean waves', 'protecting their hidden den', 'foraging for food in deep winter snow', 'camouflaging into bright green leaves', 'drifting peacefully along deep sea currents', 'watching carefully from a high tree branch', 'running free across open plains', 'cracking open a clam shell with a rock'],
    hardEnvironments: ['in the windswept Arctic tundra', 'deep in the tropical Amazon rainforest', 'among the vibrant tropical coral reefs', 'on a rugged snow-covered mountain peak', 'in a dark whispering ancient forest', 'across the golden African savanna plains', 'in a sunlit meadow of spring wildflowers', 'near a roaring mountain waterfall canyon', 'under a vast starry night sky', 'during a spectacular glowing aurora borealis']
  },
  'Food': {
    easySubjects: ['apple', 'banana', 'orange', 'strawberry', 'grape', 'carrot', 'potato', 'tomato', 'pizza slice', 'burger', 'cookie', 'donut', 'cupcake', 'ice cream cone', 'cheese slice', 'bread loaf', 'egg', 'taco', 'sushi roll', 'cake'],
    easyAdjectives: ['sweet', 'hot', 'cold', 'fresh', 'tasty', 'yummy', 'big', 'delicious', 'ripe', 'juicy', 'spicy', 'salty'],
    mediumSubjects: ['bowl of soup', 'plate of spaghetti', 'pancake stack', 'sandwich', 'fruit salad', 'bucket of popcorn', 'cup of coffee', 'glass of orange juice', 'chocolate bar', 'hot dog', 'waffle', 'slice of pie'],
    mediumActions: ['with steam rising up', 'dripping with sweet syrup', 'melting rapidly in the sun', 'covered in colorful sprinkles', 'topped with a red cherry', 'sitting on a porcelain plate', 'beside a shiny fork and knife', 'neatly cut in half', 'sizzling in a hot pan', 'overflowing from the cup'],
    mediumLocations: ['on a rustic wooden kitchen table', 'at a sunny family picnic', 'in a school lunchbox', 'in a cozy corner cafe', 'on a diner service tray', 'in a bakery shop window', 'next to a crackling campfire', 'on a breakfast plate', 'at a crowded birthday party', 'inside a dark movie theater'],
    hardSubjects: ['a luxurious Thanksgiving roasted turkey', 'a grand three-tiered wedding cake', 'a steaming bowl of spicy Japanese ramen', 'a beautiful platter of fresh sashimi and sushi', 'a rich warm chocolate fondue fountain', 'a colorful gourmet charcuterie board', 'a tower of pastel French macarons', 'a sizzling skillet of fajitas', 'a breakfast spread with croissants and jam', 'a fancy glass bottle of glowing magical elixir'],
    hardActions: ['arranged perfectly for a magazine photo', 'garnished with fresh green herbs', 'melting slowly under warm restaurant lights', 'bubbling over a hot stove fire', 'drizzled with thick rich chocolate sauce', 'reflecting warm ambient candlelight', 'cooling on a white marble countertop', 'sliced open displaying beautiful layers', 'served next to a glass of red wine', 'dusted lightly with powdered sugar'],
    hardEnvironments: ['in a modern Michelin-star restaurant', 'at a rustic outdoor vineyard festival', 'inside a cozy winter cabin kitchen', 'at a bustling Asian street food market', 'in a grand medieval royal banquet hall', 'during a sunny garden brunch party', 'in a futuristic cyberpunk noodle shop', 'in a fantasy tavern with wooden tables', 'at a crowded beachside barbecue grill', 'during a cozy family holiday dinner']
  },
  'Nature': {
    easySubjects: ['tree', 'flower', 'leaf', 'grass', 'rock', 'cloud', 'sun', 'moon', 'star', 'river', 'lake', 'mountain', 'hill', 'rain', 'snow', 'wind', 'fire', 'sea', 'shell', 'mushroom'],
    easyAdjectives: ['tall', 'green', 'bright', 'warm', 'cold', 'beautiful', 'wild', 'clean', 'quiet', 'dry'],
    mediumSubjects: ['waterfall', 'campfire', 'desert cactus', 'palm tree', 'rainbow', 'volcano', 'iceberg', 'pine cone', 'spider web', 'autumn leaf'],
    mediumActions: ['cascading down', 'crackling with sparks', 'growing in sand', 'blowing in the wind', 'stretching across the sky', 'spewing smoke', 'floating in water', 'covered in dew', 'catching a fly', 'falling slowly'],
    mediumLocations: ['in a deep canyon', 'in a dark forest', 'in the hot desert', 'near a tropical beach', 'over a green valley', 'in the ocean', 'in a snowy field', 'in a mountain meadow', 'in a suburban garden', 'along a rocky cliff'],
    hardSubjects: ['a raging forest fire', 'a peaceful sunlit glade filled with wildflowers', 'a dramatic lightning strike hitting a lone tree', 'a massive glacier calving', 'a dense jungle path lit by shafts of sunlight', 'a field of lavender stretching to the horizon', 'a crystal cave filled with giant minerals', 'a windswept sand dune under a crescent moon', 'a rocky coastline battered by massive waves', 'a serene mountain lake reflecting sunrise'],
    hardActions: ['illuminating the surroundings', 'casting long dramatic shadows', 'echoing with distant thunder', 'cracking and splashing', 'whispering in the breeze', 'glowing with natural light', 'shifting slowly over time', 'mirroring the sky perfectly', 'eroding the ancient rocks', 'creating a magical atmosphere'],
    hardEnvironments: ['in the heart of a national park', 'high in the alpine zone', 'deep in an unexplored cavern', 'along the volcanic ring of fire', 'across the vast Siberian taiga', 'in a protected nature reserve', 'on a remote uninhabited island', 'in a surreal fantasy landscape', 'during a spectacular solar eclipse', 'under the dazzling aurora borealis']
  },
  'Objects': {
    easySubjects: ['book', 'cup', 'clock', 'key', 'pencil', 'scissors', 'umbrella', 'hat', 'shoe', 'glasses', 'phone', 'ring', 'balloon', 'bag', 'lamp', 'chair', 'table', 'mirror', 'candle', 'key'],
    easyAdjectives: ['old', 'new', 'red', 'blue', 'heavy', 'light', 'shiny', 'dusty', 'broken', 'small'],
    mediumSubjects: ['vintage camera', 'magnifying glass', 'telescope', 'treasure chest', 'compass', 'guitar', 'violin', 'microscope', 'typewriter', 'lantern'],
    mediumActions: ['reflecting the light', 'sitting on a desk', 'pointing at the sky', 'overflowing with coins', 'showing north direction', 'leaning against a wall', 'resting in a case', 'examining a slide', 'holding a blank sheet', 'flickering with flame'],
    mediumLocations: ['in an old dusty attic', 'on a student desk', 'in a cozy library', 'in a secret cave', 'in a traveler backpack', 'on a music stage', 'in a high school lab', 'on a writer wooden table', 'in a dark hallway', 'next to a fireplace'],
    hardSubjects: ['an ornate golden grandfather clock', 'a dusty leather-bound spellbook', 'a highly detailed model ship in a bottle', 'an antique brass pocket watch', 'a beautifully carved wooden jewelry box', 'a mechanical typewriter with silver keys', 'a glowing neon sign displaying retro text', 'a crystal chandelier hanging from the ceiling', 'a vintage record player spinning vinyl', 'a hand-crafted glass chess set'],
    hardActions: ['ticking with rhythmic precision', 'emitting soft glowing sparkles', 'displaying intricate tiny sails', 'showing exposed spinning gears', 'filled with sparkling gemstones', 'typing mysterious words', 'casting a bright colorful glow', 'reflecting light in all directions', 'playing a classical melody', 'arranged in an intense chess match'],
    hardEnvironments: ['in a Victorian mansion parlor', 'in an ancient wizard study chamber', 'in a modern maritime museum exhibit', 'in a watchmaker repair shop', 'on a bedroom vanity table', 'in a retro writer office cabin', 'in a diner window at midnight', 'in a grand palace ballroom', 'in a cozy living room corner', 'on a glass table in a quiet study']
  },
  'Vehicles': {
    easySubjects: ['car', 'bicycle', 'train', 'airplane', 'boat', 'truck', 'bus', 'rocket', 'subway', 'tractor', 'helicopter', 'scooter', 'van', 'taxi', 'ship'],
    easyAdjectives: ['fast', 'slow', 'red', 'yellow', 'big', 'long', 'shiny', 'noisy', 'old', 'new'],
    mediumSubjects: ['steam locomotive', 'sports car', 'sailboat', 'rescue helicopter', 'submarine', 'monster truck', 'hot air balloon', 'police cruiser', 'fire engine', 'motorcycle'],
    mediumActions: ['puffing white smoke', 'speeding down a highway', 'sailing across a lake', 'flying over skyscrapers', 'submerging in deep water', 'crushing smaller cars', 'floating peacefully in the air', 'flashing blue lights', 'sounding a loud siren', 'riding on a curvy road'],
    mediumLocations: ['on steel railway tracks', 'on a racetrack asphalt', 'in a windy bay', 'near a hospital pad', 'in the dark ocean', 'in a dirt arena', 'above green hills', 'in a city street', 'at a fire station', 'along a scenic coast'],
    hardSubjects: ['a futuristic flying car with neon trails', 'an old wooden pirate ship in a storm', 'a steampunk airship with brass gears', 'a high-speed bullet train crossing a gorge', 'a deep-sea research submarine', 'a massive space cargo freighter ship', 'a vintage double-decker bus on cobblestone', 'a customized luxury hypercar', 'a search-and-rescue helicopter in a blizzard', 'a retro motorcycle with a sidecar'],
    hardActions: ['weaving between futuristic towers', 'battling giant waves and sea monsters', 'sailing majestically through clouds', 'speeding over a high steel bridge', 'illuminating the ocean abyss with searchlights', 'approaching a docking bay in orbit', 'navigating narrow old town streets', 'parked in front of a modern mansion', 'hoisting a survivor from freezing water', 'speeding along a windswept mountain road'],
    hardEnvironments: ['in a neon-lit cyberpunk metropolis', 'in the middle of the raging Atlantic Ocean', 'above a Victorian industrial city', 'in a deep valley in the Swiss Alps', 'near a hydrothermal vent at the ocean floor', 'in the vast emptiness of outer space', 'in historic downtown London', 'during a luxury car show event', 'in the remote Alaskan wilderness', 'along the historic Route 66 at sunset']
  },
  'Sports': {
    easySubjects: ['ball', 'hoop', 'bat', 'racket', 'shoe', 'skateboard', 'helmet', 'glove', 'net', 'whistle', 'bicycle', 'cup', 'goal', 'skate', 'jersey'],
    easyAdjectives: ['new', 'dirty', 'round', 'heavy', 'fast', 'worn', 'bright', 'clean', 'broken', 'pro'],
    mediumSubjects: ['basketball player', 'soccer player', 'tennis player', 'surfer', 'runner', 'skater', 'gymnast', 'swimmer', 'cyclist', 'golfer'],
    mediumActions: ['dunking the ball', 'kicking towards a net', 'hitting a volley', 'riding a wave', 'crossing the finish line', 'doing a kickflip', 'performing a flip', 'diving into a pool', 'racing up a hill', 'swinging a club'],
    mediumLocations: ['on an indoor court', 'in a grassy stadium', 'at a clay court', 'in the blue ocean', 'on a red running track', 'at a concrete skatepark', 'in a gymnastics hall', 'at an Olympic pool', 'on a mountain road', 'on a green golf course'],
    hardSubjects: ['a professional snowboarder in mid-air', 'a Formula 1 race car at high speed', 'a rock climber scaling a cliff', 'a deep-sea diver surrounded by fish', 'a figure skater spinning on ice', 'a mountain biker jumping over a gap', 'a weightlifter lifting a heavy barbell', 'a professional surfer in a tube wave', 'a hockey goalie blocking a shot', 'an archer aiming at a target'],
    hardActions: ['performing a complex grab trick', 'drifting around a sharp track corner', 'searching for the next handhold', 'exploring a colorful shipwreck', 'gliding gracefully under spotlights', 'landing cleanly on a dirt ramp', 'straining with intense concentration', 'riding inside a giant curling wave', 'sliding across the ice to save a goal', 'releasing a shot with perfect form'],
    hardEnvironments: ['high above a snowy alpine resort', 'during a rainy grand prix race', 'on a vertical red sandstone wall', 'deep in the tropical Pacific ocean', 'in a packed championship arena', 'in a dense pine forest trail', 'in a bright weightlifting hall', 'at a world-famous surf reef break', 'in a noisy hockey stadium', 'in a quiet outdoor archery range']
  },
  'Buildings': {
    easySubjects: ['house', 'barn', 'tower', 'bridge', 'castle', 'cabin', 'school', 'shop', 'church', 'mill', 'wall', 'tent', 'gate', 'hotel', 'home'],
    easyAdjectives: ['old', 'new', 'tall', 'small', 'big', 'stone', 'wooden', 'brick', 'cozy', 'haunted'],
    mediumSubjects: ['log cabin', 'lighthouse', 'windmill', 'watchtower', 'cottage', 'greenhouse', 'pagoda', 'pyramid', 'skyscraper', 'cathedral'],
    mediumActions: ['with smoke from chimney', 'flashing warning lights', 'turning its sails', 'standing on a hill', 'surrounded by gardens', 'filled with exotic plants', 'reflecting in a pond', 'rising from the desert', 'touching the clouds', 'with stained glass windows'],
    mediumLocations: ['in a snowy forest', 'on a stormy coastline', 'in a windy field', 'on a medieval border', 'in a fairytale valley', 'in a botanical garden', 'in a traditional park', 'under a scorching sun', 'in a busy city center', 'in an old European square'],
    hardSubjects: ['a sprawling Gothic cathedral', 'a futuristic skyscraper with gardens', 'a massive ancient stone temple', 'a medieval castle with drawbridge', 'a traditional Japanese pagoda', 'a research station in the desert', 'a cliffside monastery', 'a Victorian manor house', 'a futuristic underwater dome city', 'a wooden Viking longhouse'],
    hardActions: ['towering over a cobblestone square', 'illuminated by glowing green holograms', 'covered in creeping green ivy vines', 'surrounded by a deep water moat', 'framed by pink cherry blossoms', 'collecting solar power with panels', 'clinging to a sheer rock wall', 'shrouded in thick morning fog', 'glowing under deep blue water', 'with shields lining the outer walls'],
    hardEnvironments: ['in a historic European city', 'in a futuristic eco-metropolis', 'deep in the Cambodian jungle', 'on a misty highland cliff', 'near a quiet river in Kyoto', 'in the middle of the Sahara desert', 'high in the Tibetan mountains', 'in the English countryside', 'at the bottom of the Pacific Ocean', 'along a rocky Norwegian fjord']
  },
  'Fantasy': {
    easySubjects: ['wand', 'hat', 'potion', 'fairy', 'dragon', 'sword', 'shield', 'crown', 'ring', 'crystal', 'spell', 'key', 'cape', 'map', 'book'],
    easyAdjectives: ['magic', 'glowing', 'dark', 'gold', 'old', 'mystic', 'flying', 'tiny', 'giant', 'shiny'],
    mediumSubjects: ['cute dragon', 'wizard', 'mermaid', 'unicorn', 'phoenix', 'goblin', 'elf archer', 'griffin', 'spellbook', 'treasure map'],
    mediumActions: ['sitting on gold coins', 'casting a glowing spell', 'sitting on a rock', 'galloping on a rainbow', 'rising from ashes', 'stealing a gemstone', 'aiming at a target', 'flying through clouds', 'floating in mid-air', 'pointing to a secret path'],
    mediumLocations: ['in a dark stone cave', 'in a library tower', 'in the deep ocean', 'in an enchanted forest', 'high in the sky', 'in a dirty dungeon', 'on a tall tree branch', 'near a high mountain', 'on a wizard desk', 'on a dusty table'],
    hardSubjects: ['a majestic phoenix rising from flames', 'a dark wizard summoning a dragon', 'a magical gate opening to another realm', 'an elven city built in giant trees', 'a knight fighting a fire-breathing dragon', 'a water spirit emerging from a waterfall', 'a steampunk airship docked at a tower', 'a tree-like forest guardian waking up', 'a hidden cave filled with glowing crystals', 'a witch brewing a bubbling green potion'],
    hardActions: ['spreading glowing orange wings', 'swirling dark purple energy clouds', 'emitting a blinding white light portal', 'connected by rope bridges and lanterns', 'swinging a sword with glowing runes', 'shaping water droplets into animals', 'spinning brass propellers and gears', 'stretching wooden limbs covered in moss', 'reflecting light in multiple colors', 'throwing ingredients into a copper cauldron'],
    hardEnvironments: ['above a burning volcanic landscape', 'in a grand arcane academy hall', 'in an ancient stone ruin sanctuary', 'in the canopy of an enchanted forest', 'on a windswept volcanic battlefield', 'in a deep blue mountain river canyon', 'high above a Victorian industrial city', 'in a quiet autumn woodland glade', 'deep inside a legendary mountain cave', 'in a spooky cobweb-filled dungeon room']
  },
  'Space': {
    easySubjects: ['rocket', 'alien', 'planet', 'star', 'moon', 'rover', 'comet', 'sun', 'meteor', 'satellite', 'galaxy', 'capsule', 'telescope', 'ship', 'crater'],
    easyAdjectives: ['red', 'far', 'bright', 'cold', 'hot', 'giant', 'tiny', 'shiny', 'dark', 'new'],
    mediumSubjects: ['astronaut', 'space shuttle', 'space station', 'lunar lander', 'ufo', 'robot explorer', 'ringed planet', 'asteroid', 'telescope', 'space suit'],
    mediumActions: ['floating in zero gravity', 'launching into orbit', 'orbiting a planet', 'landing on the moon', 'beaming a green light', 'collecting soil samples', 'spinning in space', 'speeding through space', 'pointed at a nebula', 'displayed on a stand'],
    mediumLocations: ['in deep space', 'above a blue planet', 'near a yellow star', 'in a dusty crater', 'above a small town', 'on a red desert surface', 'near a colorful nebula', 'in an asteroid belt', 'in an observatory dome', 'in a high-tech lab'],
    hardSubjects: ['an astronaut playing a saxophone on an alien moon', 'a space station orbiting a massive black hole', 'a futuristic spaceship navigating an asteroid belt', 'a lunar colony with dome structures', 'a deep-space probe exploring a gas giant', 'an alien city with tall glass towers', 'a spaceship docking at a station in orbit', 'a star collapsing into a colorful supernova', 'a solar sail ship sailing on starlight', 'an astronaut scientist discovering glowing plants'],
    hardActions: ['reflecting two colorful moons on the visor', 'bending light and gravity around its edges', 'dodging giant tumbling space rocks', 'connected by transparent tubes and tunnels', 'flying close to massive swirling storms', 'glowing under three distant red suns', 'aligning with precision thruster fires', 'ejecting rings of plasma and dust', 'unfolding large reflective silver sails', 'analyzing a flower with a scanning beam'],
    hardEnvironments: ['on a purple sandy desert surface', 'in the gravitational pull of a black hole', 'in a dense field of gray space debris', 'on the gray dusty surface of the moon', 'in the upper atmosphere of a blue planet', 'under a dark sky filled with alien constellations', 'above a planet with glowing city lights', 'in the middle of a vibrant purple nebula', 'in the solar wind of a nearby blue star', 'inside an alien cave with glowing crystals']
  },
  'Technology': {
    easySubjects: ['computer', 'robot', 'mouse', 'keyboard', 'screen', 'phone', 'printer', 'cable', 'battery', 'chip', 'gear', 'button', 'disk', 'camera', 'plug'],
    easyAdjectives: ['smart', 'fast', 'high-tech', 'new', 'old', 'broken', 'mini', 'digital', 'green', 'black'],
    mediumSubjects: ['robotic arm', 'server rack', 'hologram', 'drone', 'vr headset', 'microscope', 'smart watch', 'circuit board', 'solar panel', 'controller'],
    mediumActions: ['soldering a chip', 'blinking blue lights', 'displaying a 3D model', 'flying through the air', 'projecting digital grid', 'showing bacteria cells', 'tracking heart rate', 'connected with wires', 'charging under sun', 'controlling a game'],
    mediumLocations: ['in a modern factory', 'in a cold data center', 'on a clean office desk', 'in a public park', 'on a user head', 'in a scientific lab', 'on a jogger wrist', 'on an engineer workbench', 'on a house roof', 'in a living room'],
    hardSubjects: ['a cybernetic server room with glowing wires', 'a hologram projector displaying a rotating city', 'a robotic dog playing fetch in a park', 'a smart home kitchen preparing food autonomously', 'a quantum computer surrounded by cooling pipes', 'a hacker station with multiple glowing screens', 'a high-tech automated drone delivery hub', 'a bio-mechanical hand drawing a sketch', 'a virtual reality user climbing a digital mountain', 'a factory assembly line with robotic arms'],
    hardActions: ['routing data streams with neon colors', 'floating above a metallic silver base', 'carrying a glowing yellow ball', 'slicing vegetables with precise laser beams', 'condensing water vapor into icy frost clouds', 'scrolling green code lines rapidly', 'sorting cargo boxes into delivery slots', 'holding a pencil with carbon fiber joints', 'reaching for a grid-based rock hold', 'welding car parts with bright orange sparks'],
    hardEnvironments: ['inside a high-security tech facility', 'in a dark cyberpunk laboratory room', 'in a modern eco-friendly city park', 'in a luxury smart apartment kitchen', 'in a scientific research laboratory basement', 'in a messy programmer bedroom workstation', 'on the rooftop of a city building at night', 'on a clean engineering design table', 'in a bright virtual reality simulation room', 'in a heavy industrial manufacturing plant']
  },
  'Jobs': {
    easySubjects: ['doctor', 'nurse', 'teacher', 'chef', 'artist', 'driver', 'pilot', 'police', 'farmer', 'builder', 'singer', 'writer', 'dentist', 'baker', 'actor'],
    easyAdjectives: ['busy', 'kind', 'happy', 'clever', 'strong', 'helpful', 'fast', 'pro', 'skilled', 'smart'],
    mediumSubjects: ['firefighter', 'astronaut', 'scientist', 'detective', 'gardener', 'mechanic', 'reporter', 'lifeguard', 'veterinarian', 'photographer'],
    mediumActions: ['spraying water on fire', 'floating in a space suit', 'looking at a test tube', 'examining clues with glass', 'watering green plants', 'fixing a car engine', 'speaking into a microphone', 'watching waves with binoculars', 'bandaging a dog leg', 'taking a photo with camera'],
    mediumLocations: ['at a burning building', 'near a spaceship hatch', 'in a chemistry laboratory', 'in a dark alleyway', 'in a greenhouse garden', 'in an auto repair garage', 'in front of a news camera', 'on a sandy beach tower', 'in an animal clinic room', 'at a scenic mountain lookout'],
    hardSubjects: ['a deep-sea marine biologist in a submarine', 'an archaeologist discovering an ancient mask in a tomb', 'a blacksmith forging a sword in a hot smithy', 'a surgeon performing a complex operation', 'a wildlife photographer hiding in bushes', 'a fashion designer pinning a dress on a mannequin', 'a glassblower shaping red-hot liquid glass', 'an astronaut scientist drilling for ice on Mars', 'a conductor leading a grand orchestra orchestra', 'a detective investigating a crime scene at night'],
    hardActions: ['watching glowing jellyfish through a round window', 'carefully brushing dust off a golden artifact', 'striking glowing orange metal with a hammer', 'focused under bright surgical dome lights', 'aiming a large camera lens at a tiger', 'draping colorful silk fabric with pins', 'blowing air through a long iron pipe', 'collecting soil samples in a sealed tube', 'waving a baton with dramatic arm gestures', 'dusting a door handle for fingerprint dust'],
    hardEnvironments: ['deep in the dark ocean abyss', 'inside an ancient Egyptian stone pyramid room', 'in a rustic stone workshop with glowing forge', 'in a clean white hospital operating room', 'in a dense tropical jungle meadow at dawn', 'in a bright modern design studio office', 'in a hot glass factory workshop', 'on the cold red surface of Mars', 'on a stage in a grand concert hall', 'in a messy old office room at midnight']
  },
  'Holidays': {
    easySubjects: ['gift', 'card', 'tree', 'egg', 'mask', 'star', 'flag', 'cake', 'bell', 'hat', 'rose', 'heart', 'sweets', 'lights', 'toy'],
    easyAdjectives: ['happy', 'merry', 'bright', 'scary', 'spooky', 'gold', 'red', 'sweet', 'fun', 'jolly'],
    mediumSubjects: ['carved pumpkin', 'Christmas stocking', 'turkey platter', 'Easter basket', 'New Year fireworks', 'birthday cake', 'valentines card', 'Halloween skeleton', 'santa hat', 'wreath'],
    mediumActions: ['glowing in the dark', 'hanging by a fireplace', 'placed on dinner table', 'filled with colorful eggs', 'exploding in the sky', 'decorated with candles', 'decorated with paper hearts', 'standing near a tombstone', 'sitting on a gift box', 'hanging on a front door'],
    mediumLocations: ['on a front porch steps', 'in a cozy living room', 'at a family dining table', 'on the green grass lawn', 'above a city skyline', 'at a party table', 'on a wooden writing desk', 'in a spooky graveyard yard', 'under a Christmas tree', 'in a festive hallway entry'],
    hardSubjects: ['a grand masquerade ballroom decorated for New Year', 'a spooky haunted house lawn decorated for Halloween', 'a cozy living room with a glowing fireplace and tree', 'a vibrant street parade float with balloons', 'a Thanksgiving dinner table with family food spread', 'a romantic candlelit dinner setting for Valentine', 'a grand Easter egg hunt field with hidden eggs', 'a beach bonfire party celebrating summer solstice', 'a colorful carnival parade with dancers and confetti', 'a winter cottage decorated with fairy lights'],
    hardActions: ['filled with dancers wearing elegant masks', 'with skeletons and jack-o-lanterns under a moon', 'with stockings hanging and presents piled high', 'showered with colorful paper confetti and streamers', 'featuring a large roasted turkey centerpiece', 'with red roses in a glass vase', 'among bushes and spring flower beds', 'with people dancing around sparks and flames', 'moving slowly down a crowded city street', 'surrounded by deep white winter snow drift'],
    hardEnvironments: ['in a luxury hotel banquet hall', 'in front of an old creaky house', 'inside a warm rustic log cabin', 'on a busy city avenue street', 'in a festive family dining room', 'in a quiet high-end restaurant corner', 'in a public park garden lawn', 'on a sandy ocean beach coast', 'in a historic downtown parade route', 'in a quiet mountain village at night']
  },
  'Emotions': {
    easySubjects: ['smile', 'tear', 'heart', 'cloud', 'sun', 'frown', 'hand', 'face', 'shout', 'hug', 'gift', 'star', 'flower', 'key', 'cross'],
    easyAdjectives: ['happy', 'sad', 'angry', 'scared', 'calm', 'lonely', 'warm', 'cold', 'joyful', 'shy'],
    mediumSubjects: ['crying person', 'joyful child', 'shocked face', 'angry storm cloud', 'peaceful meditator', 'anxious scribbles', 'excited puppy', 'lonely silhouette', 'comforting hand', 'triumphant peak'],
    mediumActions: ['under a rain cloud', 'jumping high in air', 'with wide open eyes', 'shooting lightning bolts', 'sitting in cross-legged pose', 'tangled in messy loops', 'wagging its tail fast', 'standing under streetlamp', 'holding another small hand', 'raising arms in victory'],
    mediumLocations: ['in a puddle of water', 'under a bright yellow sun', 'against a blank wall', 'over a dark landscape', 'in a quiet green garden', 'inside a chaotic empty brain', 'on a sunny grass field', 'on a foggy old bridge', 'against a soft background', 'on a mountain summit ridge'],
    hardSubjects: ['a person standing on a mountain peak feeling victorious', 'an abstract representation of anxiety and chaos', 'a serene zen garden symbolizing peace and calm', 'a lonely figure walking down a long foggy road', 'a warm embrace between two long-lost friends', 'a person looking in a mirror seeing a shadow', 'an explosion of colorful paint symbolizing creativity', 'a quiet library corner representing cozy comfort', 'a person trapped in a glass jar representing isolation', 'a child laughing under a summer sprinkler shower'],
    hardActions: ['with arms raised high towards golden sunbeams', 'drawn as tangled sharp black scribbles and shapes', 'with perfectly combed sand circles and smooth rocks', 'under the dim orange glow of a single streetlamp', 'surrounded by floating warm orange light bubbles', 'with a reflection that has a different expression', 'splattering in abstract messy paths and dots', 'sitting with a steaming mug and open book', 'tapping hands against the transparent glass walls', 'with water droplets catching the bright afternoon light'],
    hardEnvironments: ['on the summit of a high rocky mountain peak', 'in a dark empty void of chaotic thoughts', 'in a quiet temple courtyard in Kyoto', 'on a long windswept countryside road at night', 'at a crowded train station platform arrival area', 'in a dim moonlit bedroom setting', 'against a clean white museum gallery wall', 'in a warm wood-paneled reading alcove room', 'on a wooden table in an empty warehouse', 'in a green grassy backyard garden lawn']
  },
  'Mythology': {
    easySubjects: ['crown', 'sword', 'shield', 'bolt', 'hammer', 'wing', 'horn', 'ring', 'mask', 'altar', 'temple', 'hero', 'statue', 'bow', 'spear'],
    easyAdjectives: ['divine', 'ancient', 'mythic', 'gold', 'stone', 'magic', 'sacred', 'giant', 'dark', 'lost'],
    mediumSubjects: ['majestic unicorn', 'scary cyclops', 'sphinx statue', 'pegasus horse', 'minotaur maze', 'thor hammer', 'zeus bolt', 'anubis mask', 'poseidon trident', 'phoenix bird'],
    mediumActions: ['galloping across a rainbow', 'guarding a stone cave', 'sitting in front of pyramid', 'soaring over high hills', 'running in stone corridors', 'striking a mountain peak', 'glowing with white electricity', 'weighing a gold heart', 'stirring the ocean water', 'nesting in a fire nest'],
    mediumLocations: ['in a fantasy sky', 'in a rocky mountain canyon', 'in the hot Egyptian desert', 'above white fluffy clouds', 'in an underground maze', 'on an altar stone pedestal', 'in the clouds of Mount Olympus', 'inside an ancient tomb chamber', 'in a stormy ocean bay', 'on a burning volcanic peak'],
    hardSubjects: ['Zeus holding a glowing lightning bolt on Mount Olympus', 'Anubis weighing a human heart against a white feather', 'Thor battling the giant Midgard sea serpent in a storm', 'Poseidon riding a chariot drawn by sea horses in waves', 'a majestic pegasus flying past a large stone temple', 'a scary multi-headed Hydra emerging from a green swamp', 'a golden phoenix rising from an altar of flames', 'the Valkyries riding winged horses through storm clouds', 'a sphinx asking a riddle to a traveler near ruins', 'a centaur archer shooting a flaming arrow at night'],
    hardActions: ['surrounded by swirling dark storm clouds and sparks', 'inside a detailed sandstone tomb lit by torches', 'striking the massive water dragon with a hammer', 'holding a golden trident that splits the waves', 'with white wings spread wide near marble pillars', 'hissing with green venom dripping from fangs', 'igniting dry wood with magical orange fire sparks', 'charging along a path of glowing rainbow light', 'sitting on a carved pedestal covered in moss', 'pulling back a bowstring with intense strength'],
    hardEnvironments: ['high in the sky above Mount Olympus temple', 'in a hidden chamber of an Egyptian pyramid', 'in the middle of a dark raging North Sea storm', 'deep in the underwater kingdom of Atlantis', 'on a high mountain peak overlooking ancient Greece', 'in a dark murky jungle swamp with thick vines', 'on a circular stone temple altar platform', 'across the glowing sky bridge of Valhalla', 'among the ancient crumbling ruins of a desert city', 'in a dark pine forest under a crescent moon']
  },
  'Abstract Concepts': {
    easySubjects: ['spiral', 'grid', 'circle', 'square', 'triangle', 'arrow', 'cross', 'loop', 'star', 'wave', 'line', 'dot', 'cube', 'prism', 'sphere'],
    easyAdjectives: ['simple', 'complex', 'neat', 'messy', 'curved', 'straight', 'geometric', 'surreal', 'fluid', 'cosmic'],
    mediumSubjects: ['melting clock', 'brain lock', 'lightbulb plant', 'infinity loop', 'hourglass sand', 'yin yang circle', 'maze puzzle', 'puzzle piece', 'floating staircase', 'portal gate'],
    mediumActions: ['dripping over tree branch', 'unlocked by a key', 'containing a growing tree', 'flowing in space path', 'running out of time', 'balancing dark and light', 'leading to nowhere', 'connecting together', 'climbing to the sky', 'glowing with green light'],
    mediumLocations: ['in a surreal dream landscape', 'against a blank background', 'on a wooden table top', 'in a dark starry sky', 'on a flat surface', 'in a geometric frame', 'in a white empty room', 'in a wooden floor grid', 'in a misty clouds area', 'in a futuristic portal room'],
    hardSubjects: ['a surreal landscape with floating islands and rivers', 'an abstract visualization of time passing with hourglasses', 'a dreamscape with doors floating in a cosmic void', 'a labyrinth of staircases leading in different directions', 'an abstract representation of thoughts as glowing paths', 'a melting pocket watch draped over a barren tree branch', 'a geometric prism splitting a white light into a rainbow', 'a surreal giant keyhole in the sky showing stars', 'an abstract composition of overlapping geometric shapes', 'a surreal tree with roots wrapping around a glowing globe'],
    hardActions: ['with waterfalls flowing upwards into the sky clouds', 'with autumn leaves and sand grains falling together', 'with stars and nebulas visible behind open doors', 'defying gravity with figures walking upside down', 'connecting together in a complex colorful net grid', 'with distorted numbers dripping onto dry desert sand', 'casting a bright multi-colored fan of light rays', 'with a key floating nearby reflecting blue starlight', 'painted with vibrant colors and thick black outlines', 'with branches extending into a dark cosmic night sky'],
    hardEnvironments: ['in a surreal dream world without gravity', 'in a conceptual timeless space of ideas', 'in a cosmic dark blue nebulae background', 'in an impossible M.C. Escher style building', 'inside a glowing digital mind visualization', 'across a vast barren orange desert plain', 'against a dark minimalist gallery exhibition wall', 'high in the clouds of a fantasy cosmos', 'in a clean contemporary art museum room', 'in a dark space void filled with floating stars']
  }
};

// Generate prompt databases
const prompts = {
  easy: [],
  medium: [],
  hard: []
};

const promptCategories = {}; // maps prompt text -> category name
const promptDifficultyMap = {}; // maps prompt text -> difficulty

// Helper to shuffle array
function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

logger.info('Initializing DrawBattle Prompt Database...');

const categories = Object.keys(categoryData);

// Generate prompts for each category
for (const cat of categories) {
  const data = categoryData[cat];

  // 1. EASY PROMPTS: Adjective + Subject (Goal: 125 prompts per category)
  const easyTemp = [];
  for (const subj of data.easySubjects) {
    for (const adj of data.easyAdjectives) {
      easyTemp.push(`a ${adj} ${subj}`);
    }
  }
  shuffle(easyTemp);
  const easySlice = easyTemp.slice(0, 125);
  for (const p of easySlice) {
    prompts.easy.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'easy';
  }

  // 2. MEDIUM PROMPTS: Subject + Action + Location (Goal: 125 prompts per category)
  const medTemp = [];
  for (const subj of data.mediumSubjects) {
    for (const act of data.mediumActions) {
      for (const loc of data.mediumLocations) {
        medTemp.push(`${subj} ${act} ${loc}`);
      }
    }
  }
  shuffle(medTemp);
  const medSlice = medTemp.slice(0, 125);
  for (const p of medSlice) {
    prompts.medium.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'medium';
  }

  // 3. HARD PROMPTS: Subject + Action + Environment (Goal: 125 prompts per category)
  const hardTemp = [];
  for (const subj of data.hardSubjects) {
    for (const act of data.hardActions) {
      for (const env of data.hardEnvironments) {
        hardTemp.push(`${subj} ${act} ${env}`);
      }
    }
  }
  shuffle(hardTemp);
  const hardSlice = hardTemp.slice(0, 125);
  for (const p of hardSlice) {
    prompts.hard.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'hard';
  }
}

// Flatten for quick random selection
const allPrompts = [...prompts.easy, ...prompts.medium, ...prompts.hard];

logger.info(`Prompt Database Initialized successfully!`);
logger.info(`Total Easy Prompts: ${prompts.easy.length}`);
logger.info(`Total Medium Prompts: ${prompts.medium.length}`);
logger.info(`Total Hard Prompts: ${prompts.hard.length}`);
logger.info(`Total Prompts: ${allPrompts.length} (Target: >5,000)`);

// Recent prompts tracking queue to prevent repetition
const recentPrompts = new Set();
const maxRecentSize = 1200; // Track up to 1200 prompts to avoid repeats

function trackRecent(prompt) {
  recentPrompts.add(prompt);
  if (recentPrompts.size > maxRecentSize) {
    const first = recentPrompts.values().next().value;
    recentPrompts.delete(first);
  }
}

/**
 * Get a random prompt based on difficulty and category.
 * @param {'easy'|'medium'|'hard'|'mixed'|'all'} difficulty
 * @param {string} category - 'all' or one of the 15 categories
 * @returns {{ prompt: string, difficulty: 'easy'|'medium'|'hard', category: string }}
 */
export function getRandomPrompt(difficulty = 'all', category = 'all') {
  let tier = difficulty === 'mixed' || difficulty === 'all' ? 'all' : difficulty;
  let cat = category === 'all' ? 'all' : category;

  let pool = allPrompts;

  // Filter pool by difficulty first
  if (tier !== 'all') {
    pool = prompts[tier] || allPrompts;
  }

  // Filter pool by category
  if (cat !== 'all') {
    pool = pool.filter(p => promptCategories[p] === cat);
  }

  // Fallback if empty pool
  if (pool.length === 0) {
    pool = allPrompts;
  }

  // Try to select a prompt that hasn't been used recently (up to 30 attempts)
  let attempts = 0;
  let selected = pool[Math.floor(Math.random() * pool.length)];

  while (recentPrompts.has(selected) && attempts < 30) {
    selected = pool[Math.floor(Math.random() * pool.length)];
    attempts++;
  }

  trackRecent(selected);

  return {
    prompt: selected,
    difficulty: promptDifficultyMap[selected] || 'easy',
    category: promptCategories[selected] || 'Animals'
  };
}

/**
 * Get multiple unique random prompts.
 * @param {number} count
 * @param {'easy'|'medium'|'hard'|'mixed'|'all'} difficulty
 * @param {string} category
 * @returns {Array<{ prompt: string, difficulty: string, category: string }>}
 */
export function getRandomPrompts(count = 5, difficulty = 'all', category = 'all') {
  const result = [];
  for (let i = 0; i < count; i++) {
    result.push(getRandomPrompt(difficulty, category));
  }
  return result;
}

export { prompts, allPrompts, promptCategories, promptDifficultyMap };
export default prompts;
