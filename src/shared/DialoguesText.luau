export type DialoguesDict = {
	title: string,
	lines: { string },
	speaker: string?,
	portrait: string?,
	style: number?,
}

return {
	fr = {
		Test = {
			lines = {
				"<b>Test</b>, autre test. <s>test strike</s>",
				"Player, test, ponctuation. Time",
			},
			title = "TitleTest",
			speaker = "Me",
		},
	},
} :: { [string]: { [string]: DialoguesDict } }
