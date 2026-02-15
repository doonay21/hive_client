class_name BlockDependencyScanner

static func find_usages(target_uuid: String) -> Array[String]:
	var usages: Array[String] = []
	
	var programs: Array[ProgramModel] = ProgramModel.all()
	if programs.is_empty():
		programs = ProgramModel.all()

	for prog in programs:
		if is_uuid_in_grid(target_uuid, prog.grid):
			var msg = TranslationServer.translate("brain_editor.custom_blocks.used.program").format({ "name": prog.name })
			usages.append(msg)
			
	var blocks: Array[BlockModel] = BlockModel.all()
	for blk in blocks:
		if blk.uuid == target_uuid: 
			continue
		
		if is_uuid_in_grid(target_uuid, blk.grid):
			var msg = TranslationServer.translate("brain_editor.custom_blocks.used.block").format({ "name": blk.name })
			usages.append(msg)
			
	return usages

static func is_uuid_in_grid(target_uuid: String, grid_data: Array) -> bool:
	for cell in grid_data:
		if cell is Dictionary and cell.get("custom_block_uuid") == target_uuid:
			return true
	return false
