# Stage 2 — Top-down exploration

Created:
- editor-editable `Player.tscn` with CharacterBody2D, collision, Camera2D, interaction detector and AnimationPlayer;
- movement code only handles behavior; player visuals are normal Polygon2D/Line2D nodes;
- reusable DialogueBox, Interactable and RoomExit scenes;
- two connected real rooms: `MossEntrance.tscn` and `RootHall.tscn`;
- StaticBody2D boundaries/obstacles, spawn markers and scene transitions;
- German environmental dialogue for interaction-flow testing;
- MainMenu now starts in MossEntrance.

Battle mechanics are intentionally NOT part of this stage.
